require 'http/parser'
class ParserDemo
    def initialize
        @parser = Http::Parser.new(self)
    end
    def on_message_complete
        puts "Method: #{@parser.http_method}"
        puts "Path: #{@parser.request_path}"
    end

end


ParserDemo.new.parse
