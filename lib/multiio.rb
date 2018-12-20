class MultiIO
  def initialize(*targets)
     @targets = targets
  end

  def write(*args)
    @targets.each { |t| t.class == IO ? t.write(*args) : File.open(t, 'a')  { |file| file.puts(*args) } }
  end

  def close
    @targets.each(&:close)
  end
end
