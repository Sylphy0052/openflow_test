require 'socket'


c = UNIXSocket.open("/tmp/s")
c.send "a",0

