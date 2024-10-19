require_relative "./request"

class RequestParser
  # @param client [Whatever]
  def initialize(client)
    @client = client
  end

  # @return [Request]
  def parse
    normalized_lines = []

    while (line = client.gets) && (line != CRLF)
      normalized_lines << line.chomp
    end
    method, path, http_version = normalized_lines.shift.split(" ")

    headers = Headers.new
    normalized_lines.each do |line|
      if line.include?(": ")
        name, value = line.split(": ", 2)
        headers << Header.new(name, value)
      end
    end

    content_length = headers.find { _1.name == "Content-Length" }
    body = client.read(content_length.value) if content_length&.value&.positive?

    Request.new(method:, path:, http_version:, headers:, body:)
  end

  private

  attr_reader :client
end
