Status = Data.define(:code) do
  def to_s = "#{code} #{human_code}#{CRLF}"
  def human_code
    case code
    when 200 then "OK"
    when 404 then "Not Found"
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
