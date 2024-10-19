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
  r.route("/index.html", method: :get) do |_request|
    Status.new(200) => status
    Response.new(status:, headers: Headers.new, body: nil)
  end

  r.route("/user-agent", method: :get) do |request|
    user_agent = request.headers.find { _1.name == "User-Agent" }
    Headers.new => headers
    body = user_agent.value
    Status.new(body ? 200 : 404) => status
    if body
      headers << Header.new(:content_type, "text/plain")
      headers << Header.new(:content_length, body.bytesize)
    end
    Response.new(status:, headers:, body:)
  end

  r.route("/files/:file_path", method: :get) do |request|
    file_path = File.join(options[:directory], request.params["file_path"])

    if File.exist?(file_path)
      File.open(file_path) do |f|
        Status.new(200) => status
        Headers.new => headers
        headers << Header.new(:content_type, "application/octet-stream")
        headers << Header.new(:content_length, f.size)
        Response.new(status:, headers:, body: f.read)
      end
    else
      Status.new(404) => status
      Headers.new => headers
      Response.new(status:, headers:, body: nil)
    end
  end

  r.route("/echo/:message", method: :get) do |request|
    Status.new(200) => status
    body = request.params["message"]
    Headers.new => headers
    headers << Header.new(:content_type, "text/plain")
    headers << Header.new(:content_length, body.bytesize)
    Response.new(status:, headers:, body:)
  end

  r.route("/", method: :get, exact: true) do |_request|
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
    client.puts(response.to_s)
    client.close

    puts "Request completed"
  end
rescue Interrupt
  puts
  puts 'Exiting'
  exit(2)
end
