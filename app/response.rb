Status = Data.define(:code) do
  def to_s = "#{code} #{human_code}#{CRLF}"
  def human_code
    case code
    when 200 then "OK"
    when 201 then "Created"
    when 404 then "Not Found"
    end
  end
end

class Header
  def initialize(name, value)
    @name = capitalized_name(name)
    @value = normalized_value(value)
  end

  attr_reader :name, :value

  def to_s = "#{name}: #{value}#{CRLF}"

  private

  def capitalized_name(name)
    parts = name.to_s.split("_")
    return name if parts.size == 1

    parts.map(&:capitalize).join("-")
  end

  def normalized_value(value)
    case name
    when "Content-Length" then value.to_i
    else value
    end
  end
end

class Headers < Array
  def initialize(*headers)
    super(headers)
  end

  def to_s = map(&:to_s).join
end

class Response
  # @param status [Integer]
  def initialize(status:, headers: Headers.new, body: nil)
    @status = Status.new(status)
    @headers = headers
    @body = body
  end

  attr_reader :status, :headers, :body

  def to_s = "#{status_line}#{headers}#{CRLF}#{body}"
  def status_line = "#{HTTP_VERSION} #{status}"
end
