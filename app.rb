require 'sinatra/base'
require 'sinatra-websocket'
require 'redis'

class App < Sinatra::Base
  enable :inline_templates
  set :threads, []
  set :connections, []

  def redis
    @redis ||= Redis.new
  end

  def redis_sub
    @redis_sub ||= redis.dup
  end

  get '/' do
    erb :index
  end

  # works with thin only, no ruby-websocket extension for rainbows
  # example: https://github.com/simulacre/sinatra-websocket/blob/master/lib/sinatra-websocket/ext/thin/connection.rb
  get '/websocket' do
    if request.websocket?
      request.websocket do |ws|
        ws.onopen do
          settings.threads << Thread.new do
            redis_sub.subscribe 'messages' do |on|
              on.message do |channel, message|
                settings.threads.include?(Thread.current) ?
                  ws.send(message) : redis_sub.unsubscribe('messages')
              end
            end
          end
        end

        ws.onmessage do |message|
          redis.publish 'messages', message
        end

        ws.onclose do
          settings.threads.delete(settings.threads.last)
        end
      end
    end
  end

  get '/subscribe', provides: 'text/event-stream' do
    stream :keep_open do |out|
      settings.connections << out

      out.callback do
        settings.connections.delete(out)
      end

      redis_sub.subscribe 'messages' do |on|
        on.message do |channel, message|
          settings.connections.include?(out) ?
            out << "#{message}\n" : redis_sub.unsubscribe('messages')
        end
      end
    end
  end

  post '/' do
    redis.publish 'messages', params[:text]
    204 # response without entity body
  end

  run! if app_file == $0
end

__END__
@@ index
<!-- stolen with love from https://github.com/simulacre/sinatra-websocket/blob/master/examples/echochat.rb -->
<html>
  <body>
    <form id="form">
      message: <input type="text" id="input"></input>
    </form>
    <div id="msgs"></div>
  </body>

  <script type="text/javascript">
    window.onload = function(){
      (function(){
        var show = function(el){
          return function(msg){ el.innerHTML = msg + '<br />' + el.innerHTML; }
        }(document.getElementById('msgs'));

        var ws       = new WebSocket('ws://' + window.location.host + '/websocket');
        ws.onopen    = function()  { show('websocket opened'); };
        ws.onclose   = function()  { show('websocket closed'); }
        ws.onmessage = function(m) { show('websocket message: ' +  m.data); };

        var sender = function(f){
          var input     = document.getElementById('input');
          f.onsubmit    = function(){
            ws.send(input.value);
            input.value = "";
            return false;
          }
        }(document.getElementById('form'));
      })();
    }
  </script>
</html>
