require 'socket'

UNIXServer.open("/tmp/s") {|serv|
  s = serv.accept
  p s.recvfrom(10)[0]     #=> "a"
}
