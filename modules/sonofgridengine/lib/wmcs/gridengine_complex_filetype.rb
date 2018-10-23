# gridengine complexes need a custom filetype

Puppet::Util::FileType.newfiletype(:gridengine_complex) do
  # TODO: target/default_target should be used to point to a
  #       specific gridengine instance and default to, well, the
  #       default.

  def read
    `qconf -sc`
  end

  def write(text)
    Tempfile.open('gridengine_complex') do |tmpfile|
      tmpfile.write(text)
      tmpfile.close
      Puppet::Util::Execution.execute(['qconf', '-Mc', tmpfile.path])
    end
  end
end
