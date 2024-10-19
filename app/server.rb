require "socket"
require "optparse"
require "pry"
require_relative "constants"
require_relative "params"
require_relative "request"
require_relative "request_parser"
require_relative "response"
require_relative "router"
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
  r.get("/index.html") do |_request|
    Response.new(status: 200)
  end

  r.get("/user-agent") do |request|
    user_agent = request.headers.find { _1.name == "User-Agent" }
    body = user_agent.value

    if body
      Headers.new(
        Header.new(:content_type, "text/plain"),
        Header.new(:content_length, body.bytesize)
      ) => headers

      Response.new(status: 200, headers:, body:)
    else
      Response.new(status: 404)
    end
  end

  r.get("/files/:file_path") do |request|
    file_path = File.join(options[:directory], request.params["file_path"])

    if File.exist?(file_path)
      File.open(file_path) do |f|
        Headers.new(
          Header.new(:content_type, "application/octet-stream"),
          Header.new(:content_length, f.size)
        ) => headers
        Response.new(status: 200, headers:, body: f.read)
      end
    else
      Response.new(status: 404)
    end
  end

  r.post("/files/:file_path") do |request|
    file_path = File.join(options[:directory], request.params["file_path"])

    File.open(file_path, "wb") do |f|
      f.write(request.body)

      Response.new(status: 201)
    end
  end

  r.get("/echo/:message") do |request|
    body = request.params["message"]
    Headers.new(
      Header.new(:content_type, "text/plain"),
      Header.new(:content_length, body.bytesize)
    ) => headers

    Response.new(status: 200, headers:, body:)
  end

  r.get("/", exact: true) do |_request|
    Response.new(status: 200)
  end
end

loop do
  Thread.start(server.accept) do |client|
    puts "Received request"

    request = RequestParser.new(client).parse
    route = router.resolve(request)
    response = route.call(request)

    logger.info(response.to_s)
    client.puts(response.to_s)
    client.close

    puts "Request completed"
  end
rescue Interrupt
  puts
  puts 'Exiting'
  exit(2)
end
