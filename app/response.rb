Status = Data.define(:code) do
  def to_s = "#{code} #{human_code}#{CRLF}"
  def human_code
    case code
    when 200 then "OK"
    when 404 then "Not Found"
    end
  end
end

class Header
  def initialize(name, value)
    @name = normalized_name(name)
    @value = value
  end

  attr_reader :name, :value

  def to_s = "#{name}: #{value}#{CRLF}"

  private

  def normalized_name(name)
    parts = name.to_s.split("_")
    return name if parts.size == 1

    parts.map(&:capitalize).join("-")
  end
end

class Headers < Array
  def to_s = map(&:to_s).join
end

Response = Data.define(:status, :headers, :body) do
  def to_s = "#{status_line}#{headers}#{CRLF}#{body}"
  def status_line = "#{HTTP_VERSION} #{status}"
end
