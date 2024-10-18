class Logger
  def info(value)
    puts "#{prefix}#{value}"
  end

  private

  def prefix
    "[SERVER]: "
  end
end
