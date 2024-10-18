class Router
  def initialize
    @routes = []
  end

  # @param route [Route]
  def add(route)
    routes << route
  end

  # @param request [Request]
  # @return [Route, nil]
  def resolve(request)
    routes.find do |route|
      route.method.to_s.upcase == request.method.to_s.upcase &&
        route.match?(request.path)
    end => route

    return route if route

    Route.new(request.path, method: request.method) do |request|
      Status.new(404) => status
      Response.new(status:, headers: Headers.new, body: nil)
    end
  end

  private

  attr_reader :request, :routes
end

class Route
  # @param constraint [Regex, String]
  # @param method [Symbol, String]
  def initialize(constraint, method:, &block)
    @constraint = constraint
    @method = method
    @block = block
  end

  attr_reader :constraint, :method

  # What to call when route matches
  def call(request)
    block.call(request)
  end

  # @param path [String]
  def match?(path) = path.match(constraint)

  private

  attr_reader :block
end
