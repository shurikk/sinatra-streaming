require 'sinatra/base'
require 'redis'

class App < Sinatra::Base
  def redis
    @redis ||= Redis.new
  end

  get '/subscribe', provides: 'text/event-stream' do
    stream :keep_open do |out|
      redis.subscribe 'messages' do |on|
        on.message do |channel, message|
          out << "#{message}\n"
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
