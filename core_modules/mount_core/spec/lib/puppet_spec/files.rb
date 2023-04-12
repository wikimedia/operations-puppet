require 'fileutils'
require 'tempfile'
require 'tmpdir'
require 'pathname'

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

  def make_absolute(path)
    path = File.expand_path(path)
    path[0] = 'c' if Puppet.features.microsoft_windows?
    path
  end

  def tmpfile(name, dir = nil)
    dir ||= Dir.tmpdir
    path = Puppet::FileSystem.expand_path(make_tmpname(name, nil).encode(Encoding::UTF_8), dir)
    PuppetSpec::Files.record_tmp(File.expand_path(path))

    path
  end

  def file_containing(name, contents)
    file = tmpfile(name)
    File.open(file, 'wb') { |f| f.write(contents) }
    file
  end

  def script_containing(name, contents)
    file = tmpfile(name)
    if Puppet.features.microsoft_windows?
      file += '.bat'
      text = contents[:windows]
    else
      text = contents[:posix]
    end
    File.open(file, 'wb') { |f| f.write(text) }
    Puppet::FileSystem.chmod(0o755, file)
    file
  end

  def tmpdir(name)
    dir = Puppet::FileSystem.expand_path(Dir.mktmpdir(name).encode!(Encoding::UTF_8))

    PuppetSpec::Files.record_tmp(dir)

    dir
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

  def dir_containing(name, contents_hash)
    dir_contained_in(tmpdir(name), contents_hash)
  end

  def dir_contained_in(dir, contents_hash)
    contents_hash.each do |k, v|
      if v.is_a?(Hash)
        Dir.mkdir(tmp = File.join(dir, k))
        dir_contained_in(tmp, v)
      else
        file = File.join(dir, k)
        File.open(file, 'wb') { |f| f.write(v) }
      end
    end
    dir
  end

  def self.record_tmp(tmp)
    # ...record it for cleanup,
    @global_tempfiles << tmp
  end

  def expect_file_mode(file, mode)
    actual_mode = '%o' % Puppet::FileSystem.stat(file).mode
    target_mode = if Puppet.features.microsoft_windows?
                    mode
                  else
                    '10' + '%04i' % mode.to_i
                  end
    expect(actual_mode).to eq(target_mode)
  end
end
