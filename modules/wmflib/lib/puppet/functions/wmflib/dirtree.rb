Puppet::Functions.create_function(:'wmflib::dirtree') do
  # returns an array of all parent dirs in a given filepath string
  # @param path The file path to parse
  # @return [String] Returns an array of path elements
  # @example pars a path
  #   dirtree('/tmp/test/path.conf') => ['/tmp', '/tmp/test']
  dispatch :dirtree do
    param 'String', :path
  end
  def dirtree(path)
    raise(Puppet::ParseError, 'dirtree requires a fully qualified path') unless path[0] == '/'
    dirs = []
    tmp_path = path
    loop do
      tmp_path = File.dirname(tmp_path)
      break if tmp_path == '/'
      dirs.push(tmp_path)
    end
    dirs
  end
end
