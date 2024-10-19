require "socket"
require "optparse"
require "pry"
require_relative "constants"
require_relative "errors"
require_relative "params"
require_relative "request"
require_relative "request_parser"
require_relative "response"
require_relative "router"
require_relative "encoder"
require_relative "logger"

logger = Logger.new

options = {}
OptionParser.new do |opts|
  opts.on("--directory=DIRECTORY", "Root file directory") do |v|
    options[:directory] = v
  end
end.parse!

logger.info("cli options provided #{options.inspect}")

server = TCPServer.new("localhost", 4221)

logger.info("Listening...")

router = Router.new do |r|
  r.get("/index.html") do |_, response|
    response.ok
  end

  r.get("/user-agent") do |request, response|
    user_agent = request.headers.find { _1.name == "User-Agent" }
    data = user_agent.value

    if data
      response.body = Body.new(data)
      response.ok
    else
      response.not_found
    end
  end

  r.get("/files/:file_path") do |request, response|
    file_path = File.join(options[:directory], request.params["file_path"])

    if File.exist?(file_path)
      File.open(file_path) do |f|
        response.body = Body.new(f.read, "application/octet-stream")
        response.ok
      end
    else
      response.not_found
    end
  end

  r.post("/files/:file_path") do |request, response|
    file_path = File.join(options[:directory], request.params["file_path"])

    File.open(file_path, "wb") do |f|
      f.write(request.body.data)
      response.created
    end
  end

  r.get("/echo/:message") do |request, response|
    body = request.params["message"]
    response.body = Body.new(body)
    response.ok
  end

  r.get("/", exact: true) do |_, response|
    response.ok
  end
end

loop do
  Thread.start(server.accept) do |client|
    logger.info "Received request"

    request = RequestParser.new(client).parse
    route = router.resolve(request)
    response = route.call(request, Response.new)
    Encoder.new(request, response).encode!

    logger.info(response.to_s)
    client.puts(response.to_s)
    client.close

    logger.info "Request completed"
  end
rescue ServerError => e
  logger.error(e.message)
rescue Interrupt
  puts
  puts 'Exiting'
  exit(2)
end
