class App
    def call(env)
        message = "Helloooooooo *intended echo*\n"
        [ 
            200,
            {'Content-Type' => 'text/plain', 'Content-Length' => message.size.to_s},
            [message]
        ]


    end
end

run App.new

