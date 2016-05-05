require 'socket'
require 'http/parser'
require 'stringio'
require 'thread'
class Tube
    def initialize(port, app)
      @server_socket = TCPServer.new(port)
      @app = app
    end

    def start
        loop do
            client_socket = @server_socket.accept
            Thread.new do
                connection = Connection.new(client_socket, @app)
                connection.process
            end
        end
    end

    def prefork(workers)
        workers.times do
            fork do
                puts "Running on Process ID: #{Process.pid}"
                start
            end
        end
    end

    class Connection
        def initialize(socket, app)
             @socket = socket
             @parser = Http::Parser.new(self)
             @app = app
         end

         def process
             until @socket.closed? || @socket.eof?
                data = @socket.readpartial(1024)
                @parser << data
             end
         end

         def on_message_complete
             puts "#{@parser.http_method} #{@parser.request_url}"
             puts "  #{@parser.headers.inspect}"

             env = {}
             @parser.headers.each_pair do |name, value|
                name = "HTTP_#{name.upcase.tr("-","_")}"
                env[name] = value
             end
             env['REQUEST_METHOD']  = @parser.http_method
             env['PATH_INFO']       = @parser.request_url
             env["rack.input"]      = StringIO.new

             send_response env
         end

         REASONS = {
             200 => 'OK', 
             404 => 'Not Found'
         }

         def send_response env
             status, headers, body = @app.call(env)
             reason = REASONS[status]    
             @socket.write "HTTP/1.1 #{status} #{reason}\r\n"
             headers.each_pair do |name, value|
                @socket.write "#{name}: #{value}\r\n"
             end
             @socket.write "\r\n"
             body.each do |chunk|
                 @socket.write chunk
             end
             body.close if body.respond_to? :close
             close
         end

         def close
             @socket.close
         end
    end

    class Builder
        attr_reader :app
        def run(app)
            @app = app
        end

        def self.parse_file(file)
            content = File.read(file)
            builder = Builder.new
            builder.instance_eval(content)
            builder.app
        end
    end
end
    
port = 3003
app = Tube::Builder.parse_file('config.ru')
server = Tube.new(port, app)
puts "Plugging in Tube at #{port}"
server.prefork 3
