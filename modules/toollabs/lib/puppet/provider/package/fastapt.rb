# 'fastapt' provider for Packages
# Instead of querying the status of each package individually, this provider
# queries the status of all installed packages in one go. This results in
# a slightly slower startup (~2 seconds) but saves 0.25 seconds per package.
#
# This provider requires apt-show-versions.
#
# To use this provider as default, add a clause
#   Package { provider => "fastapt" }
# to your puppet manifest
#
# (C) 2015 Merlijn van Deen <valhallasw@arctus.nl>
# Licensed under the MIT/Expat license

Puppet::Type.type(:package).provide :fastapt, :parent => :apt, :source => :dpkg do
  commands :showversions => "/usr/bin/apt-show-versions"
 
  def get_latest_version_hash
    output = showversions

    versions = Hash.new
    output.each_line do |line|
      if line =~ /^([^:]+)\S+\s(\S+).*\s(\S+)/
        # output is in the form of
        #   zsh-common:all/trusty 5.0.2-3ubuntu6 uptodate
        # if the package is up to date, or
        #   uuid-runtime:amd64/trusty-updates 2.20.1-5.1ubuntu20.6 upgradeable to 2.20.1-5.1ubuntu20.7
        # if the package is not up to date.
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
      # This hack overwrites def get_latest_version_hash with the resulting
      # hash. h/t to MatmaRex
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

    # if determining the version fails, fall back to the 'apt-cache policy' method
    return super
  end
end
