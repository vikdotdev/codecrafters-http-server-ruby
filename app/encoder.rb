
class Encoder
  SUPPORTED_ENCODINGS = [
    GZIP = "gzip"
  ].freeze

  def initialize(request, response)
    @request = request
    @response = response
  end

  def encode!
    if (encoding = find_supported_encoding)
      # TODO encode & change content length here
      response.headers.upsert("Content-Encoding", encoding)
    else
      # no-op, omit
    end
  end

  # @return [String]
  def find_supported_encoding
    header = request.headers.find { _1.name == "Accept-Encoding" }
    return if header.nil?

    first_supported_encoding(header.value)
  end

  private

  # @param value [Array<String>]
  def first_supported_encoding(encodings)
    encodings.find { SUPPORTED_ENCODINGS.include?(_1) }
  end

  attr_reader :request, :response
end
