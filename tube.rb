require 'socket'
require 'http/parser'
class Tube
    def initialize(port)
      @server_socket = TCPServer.new(port)
    end

    def start
        loop do
            client_socket = @server_socket.accept
            connection = Connection.new(client_socket)
            connection.process
        end
    end

    class Connection
        def initialize(socket)
             @socket = socket
             @parser = Http::Parser.new(self)
         end

         def process
             until @socket.closed? || @socket.eof?
                data = @socket.readpartial(1024)
                @parser << data
             end
         end

         def on_message_complete
             send_response
             puts "#{@parser.http_method} #{@parser.request_url}"
             puts "  #{@parser.headers.inspect}"
         end

         def send_response
             @socket.write "HTTP/1.1 200 OK\r\n"
             @socket.write "\r\n"
             @socket.write "bello!\n"
             close
         end

         def close
             @socket.close
         end
    end
end

port = 3003

server = Tube.new(port)
puts "Plugging in Tube at #{port}"
server.start
