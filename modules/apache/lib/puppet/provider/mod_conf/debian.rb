require 'fileutils'

Puppet::Type.type(:mod_conf).provide(:debian) do
  def initialize *args
    super
    @load_file = resource[:name] + '.load'
    @conf_file = resource[:name] + '.conf'
  end

  def available? file
    File.exist? File.join('/etc/apache2/mods-available', file)
  end

  def enabled? file
    target = File.join('../mods-available', file)
    Dir.chdir('/etc/apache2/mods-enabled') do
      return File.readlink(file) == target rescue nil
    end
  end

  def enable file
    target = File.join '../mods-available', file
    Dir.chdir('/etc/apache2/mods-enabled') do
      FileUtils.ln_sf(target, file)
    end
  end

  def disable file
    FileUtils.rm_f(File.join '/etc/apache2/mods-enabled', file)
  end

  def exists?
    enabled?(@load_file) && !available?(@conf_file) || enabled?(@conf_file)
  end

  def create
    enable(@load_file)
    enable(@conf_file) if available?(@conf_file)
  end

  def destroy
    disable(@load_file)
    disable(@conf_file)
  end
end
