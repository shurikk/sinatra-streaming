# sintra-streaming

## Overview

sinatra-streaming is an example application using redis pub/sub
to demonstrate streaming api endpoints

## Example

start redis server

```sh
redis-server --daemonize yes
```

install gems

```sh
bundle install
```

use thin or rainbows

```sh
bundle exec thin start -p 9292
# OR rainbows
bundle exec rainbows -p 9292 -c rainbows.conf
```

in a terminal window

```sh
$ curl -i -N http://localhost:9292/subscribe
HTTP/1.1 200 OK
Date: Sat, 26 Apr 2014 04:40:19 GMT
Status: 200 OK
Content-Type: text/event-stream;charset=utf-8
X-Content-Type-Options: nosniff
Connection: close
```

another window

```sh
$ curl -dtext="hello world" http://localhost:9292/
HTTP/1.1 204 No Content
Date: Sat, 26 Apr 2014 04:40:22 GMT
Status: 204 No Content
X-Content-Type-Options: nosniff
Connection: keep-alive
```

## References

* [Sinatra: Streaming Responses](http://www.sinatrarb.com/intro.html#Streaming%20Responses)
* [Rainbows](http://rainbows.rubyforge.org/Rainbows/Configurator.html)
* [Thin](https://github.com/macournoyer/thin/)
