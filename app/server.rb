require "socket"
require "pry"

class Logger
  def info(value)
    puts "#{prefix}#{value}"
  end

  private

  def prefix
    "[SERVER]: "
  end
end

Status = Data.define(:code) do
  def to_s = "#{code} #{human_code}#{CRLF}"
  def human_code
    case code
    when 200 then "OK"
    end
  end
end

Header = Data.define(:name, :value) do
  def to_s = "#{name.to_s.split("_").map(&:capitalize).join("-")}: #{value}#{CRLF}"
end

class Headers < Array
  def to_s = map(&:to_s).join
end

Response = Data.define(:status, :headers, :body) do
  def to_s = "#{status_line}#{headers}#{CRLF}#{body}"
  def status_line = "#{HTTP_VERSION} #{status}"
end

Route = Data.define(:constraint) do
  def match?(path) = path.match(constraint)
end

CRLF = "\r\n"
HTTP_VERSION = "HTTP/1.1"

server = TCPServer.new("localhost", 4221)
logger = Logger.new

logger.info("Listening...")

loop do
  Thread.start(server.accept) do |client|
    puts "Received request"

    Status.new(200) => status
    Headers.new => headers
    headers << Header.new(name: :content_type, value: "text/plain")
    headers << Header.new(name: :connection, value: "close")

    Response.new(status:, headers:, body: "Hello!") => response

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
