class Router
  def initialize
    @routes = []

    yield(self)
  end

  # @param route [Route]
  def add(route)
    routes << route
  end

  def route(constraint, method:, &block)
    variable_names = []
    constraint.gsub(/:(\w+)/) do |match|
      variable_names << match.slice(1..)
      "([^/]+)"
    end => pattern

    Route.new(constraint, method:, variable_names:, pattern:, &block) => route
    add(route)

    route
  end

  # @param request [Request]
  # @return [Route, nil]
  def resolve(request)
    match_data = nil
    routes.find do |route|
      same_method = route.method.to_s.upcase == request.method.to_s.upcase
      next unless same_method

      match_data = route.match(request.path)
      same_method && match_data
    end => route

    if route
      route.variable_names.each_with_index do |name, i|
        request.params[name] = match_data[i + 1]
      end

      return route
    end

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
  def initialize(constraint, method:, pattern: nil, variable_names: [], &block)
    @constraint = constraint
    @method = method
    @pattern = pattern ? /#{pattern}/ : nil
    @variable_names = variable_names
    @block = block
  end

  attr_reader :constraint, :method, :pattern, :variable_names

  # What to call when route matches
  def call(request)
    block.call(request)
  end

  # @param path [String]
  def match(path)
    return false if pattern.nil?

    pattern.match(path)
  end

  private

  attr_reader :block
end
