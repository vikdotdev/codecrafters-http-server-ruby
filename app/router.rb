class Router
  def initialize
    @routes = []

    yield(self)
  end

  # @param route [Route]
  def add(route)
    routes << route
  end

  def get(constraint, exact: false, &block)
    route(constraint, method: :get, exact:, &block)
  end

  def post(constraint, exact: false, &block)
    route(constraint, method: :post, exact:, &block)
  end

  def route(constraint, method:, exact: false, &block)
    variable_names = []
    constraint.gsub(/:(\w+)/) do |match|
      variable_names << match.slice(1..)
      "([^/]+)"
    end => pattern

    add(
      Route.new(
        constraint, method:, variable_names:, pattern:, exact:, &block
      )
    )
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

    Route.new(request.path, method: request.method) do |_, response|
      response.not_found
    end
  end

  private

  attr_reader :request, :routes
end

class Route
  # @param constraint [Regex, String]
  # @param method [Symbol, String]
  def initialize(constraint, method:, exact: false, pattern: nil, variable_names: [], &block)
    @constraint = constraint
    @method = method
    @pattern = pattern && !exact ? /#{pattern}/ : pattern
    @exact = exact
    @variable_names = variable_names
    @block = block
  end

  attr_reader :constraint, :method, :pattern, :variable_names, :exact

  # What to call when route matches
  # @param request [Request]
  # @param response [Response]
  def call(request, response)
    log(request.inspect)
    log(self.inspect)

    block.call(request, response)
    response
  end

  # @param path [String]
  def match(path)
    return false if pattern.nil?

    pattern.match(path)
  end

  private

  attr_reader :block

  def log(...)
    @logger ||= Logger.new
    @logger.info(...)
  end
end
