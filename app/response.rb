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

  def update(value)
    @value = normalized_value(value)
  end

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
    when "Accept-Encoding" then value.split(", ")
    else value
    end
  end
end

class Headers < Array
  def initialize(*headers)
    super(headers)
  end

  def upsert(name, value)
    header = find { _1.name == name }
    if header
      header.update(value)
    else
      self << Header.new(name, value)
    end
  end

  def to_s = map(&:to_s).join
end

class Response
  StatusNotSet = Class.new(ServerError)

  # @param status [Integer]
  # @param body [Body]
  def initialize(status: nil, headers: Headers.new, body: nil)
    @status = Status.new(status)
    @headers = headers
    @body = body

    headers_from_body!(body)
  end

  attr_reader :status, :body
  attr_accessor :headers

  def header(*headers)
    @headers.concat(headers)
  end

  # @param body [Body]
  def body=(body)
    headers_from_body!(body)
    @body = body
  end

  def created
    @status = Status.new(201)
  end

  def ok
    @status = Status.new(200)
  end

  def not_found
    @status = Status.new(404)
  end

  # @param value [Integer]
  def status=(value)
    @status = Status.new(value)
  end

  def to_s = "#{status_line}#{headers}#{CRLF}#{body&.data}"

  def status_line
    raise StatusNotSet if status.nil?

    "#{HTTP_VERSION} #{status}"
  end

  private

  # @param body [Body, nil]
  def headers_from_body!(body)
    return if body.nil?

    @headers << Header.new(:content_type, body.content_type)
    @headers << Header.new(:content_length, body.bytesize)
  end
end

class Body
  def initialize(data, content_type = nil, compressed: false)
    @data = data
    @content_type = content_type || "text/plain"
    @compressed = compressed
  end

  def bytesize = @data.bytesize

  def gzip!
    return data if compressed

    @compressed = true
    @data = data.gzip
  end

  attr_reader :data, :content_type, :compressed
end
