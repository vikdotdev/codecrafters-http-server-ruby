class Request
  def initialize(method:, path:, http_version:, headers:, body:)
    @method = method
    @path = path
    @http_version = http_version
    @headers = headers
    @body = body
    @params = Params.new
  end

  attr_reader :method, :path, :http_version,
              :headers, :body, :params
end
