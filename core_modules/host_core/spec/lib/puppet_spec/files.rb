require 'fileutils'
require 'tempfile'
require 'tmpdir'

# A support module for testing files.
module PuppetSpec::Files
  @global_tempfiles = []

  def self.cleanup
    until @global_tempfiles.empty?
      path = @global_tempfiles.pop
      FileUtils.rm_rf path, secure: true
    end
  end

  module_function

  def tmpfile(name, dir = nil)
    dir ||= Dir.tmpdir
    path = Puppet::FileSystem.expand_path(make_tmpname(name, nil).encode(Encoding::UTF_8), dir)
    PuppetSpec::Files.record_tmp(File.expand_path(path))

    path
  end

  # Copied from ruby 2.4 source
  def make_tmpname((prefix, suffix), n)
    prefix = (String.try_convert(prefix) ||
              raise(ArgumentError, "unexpected prefix: #{prefix.inspect}"))
    suffix &&= (String.try_convert(suffix) ||
                raise(ArgumentError, "unexpected suffix: #{suffix.inspect}"))
    t = Time.now.strftime('%Y%m%d')
    path = "#{prefix}#{t}-#{$PROCESS_ID}-#{rand(0x100000000).to_s(36)}".dup
    path << "-#{n}" if n
    path << suffix if suffix
    path
  end

  def self.record_tmp(tmp)
    # ...record it for cleanup,
    @global_tempfiles << tmp
  end
end
