require 'socket'


sock = Thread.new do
  Socket.unix_server_loop('server.sock') do |sock, addr|
    p sock
    Thread.new do
      s = sock.accept
      p s.recvfrom(10)[0]
      Thread.pass
    end
  end
end

puts 'server launched!'


def hello num
  puts "hellow num : #{num}"
end
