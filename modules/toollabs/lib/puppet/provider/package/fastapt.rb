Puppet::Type.type(:package).provide :fastapt, :parent => :apt, :source => :dpkg do
  defaultfor :domain => "toolsbeta.eqiad.wmflabs"
  commands :showversions => "/usr/bin/apt-show-versions"
  
  def get_latest_version_hash
    puts "initial glvh"

    output = showversions
    versions = Hash.new
    output.each_line do |line|
      if line =~ /^([^:\/]+)\S+\s(\S+).*\s(\S+)/
        package = $1
        current_version = $2
        new_version = $3

        if new_version == 'uptodate'
          new_version = $2
        end

        versions[package] = new_version
      end
    end

    self.class.send :define_method, :get_latest_version_hash do
      versions
    end

    return versions
  end

  def latest
    package = @resource[:name]
    version = get_latest_version_hash[package]
    
    if not version.nil?
      return version
    end

    return super.latest
  end
end
