require "socket"
require_relative "constants"
require_relative "params"
require_relative "request"
require_relative "request_parser"
require_relative "response"
require_relative "router"
require_relative "logger"

server = TCPServer.new("localhost", 4221)
logger = Logger.new

logger.info("Listening...")

router = Router.new do |r|
  r.route(/\/index.html\Z/, method: :get) do |request|
    Status.new(200) => status
    Response.new(status:, headers: Headers.new, body: nil)
  end
  r.route(/\/echo\/(.+)\Z/, method: :get) do |request|
    Status.new(200) => status
    Response.new(status:, headers: Headers.new, body: nil)
  end
  r.route(/\/\Z/, method: :get) do |request|
    Status.new(200) => status
    Response.new(status:, headers: Headers.new, body: nil)
  end
end

loop do
  Thread.start(server.accept) do |client|
    puts "Received request"

    request = RequestParser.new(client).parse
    route = router.resolve(request)
    response = route.call(request)

    logger.info(response.to_s)
    client.puts response.to_s
    client.close

    puts "Request completed"
  end
rescue Interrupt
  puts
  puts 'Exiting'
  exit(2)
end
