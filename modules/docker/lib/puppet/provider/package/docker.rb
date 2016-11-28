# Puppet package provider for `docker`.
#
# Copyright 2016 Giuseppe Lavagetto, Wikimedia Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'puppet/provider/package'

Puppet::Type.type(:package).provide(
  :docker, :parent => Puppet::Provider::Package) do

  desc 'Puppet package provider for docker.'

  has_feature :installable, :uninstallable, :versionable, :upgradeable

  commands :docker => '/usr/bin/docker'

  DOCKER_IMAGES_FORMAT_STRING = "{{.Repository}}\t{{.Tag}}\t{{.ID}}"

  def self.instances
    packages = []
    docker('images', '--format', DOCKER_IMAGES_FORMAT_STRING).split("\n").each do |line|
      repo, tag, _ = line.split "\t"
      package = {:ensure => tag, :name => repo,
              :provider => :docker}
      packages << new(package)
    end

    packages
  end

  def installed_versions
    docker('images', '--format', '{{.Tag}}', resource[:name]).split("\n")
  end

  def required_version
    should = resource[:ensure]
    case should
    when true, false, Symbol
      "#{resource[:name]}:latest"
    else
      "#{resource[:name]}:#{should}"
    end
  end

  def install
    docker('pull', required_version)
    installed_versions.each do |version|
      tag = "#{resource[:name]}:#{version}"
      next if tag == required_version
      begin
        docker('rmi', tag)
      rescue Puppet::ExecutionFailure
        Puppet.warning("Not removing image #{tag} as it is currently in use.")
      end
    end
  end

  def uninstall
    installed_versions.each do |version|
      docker('rmi', "#{resource[:name]}:#{version}")
    end
  end

  def update
    install
  end

  def query
    result = { :ensure => :absent, :name => resource[:name] }
    versions = installed_versions

    unless versions.empty?
      if versions.include?('latest')
        result[:ensure] = 'latest'
      else
        result[:ensure] = versions.sort{ |x, y| Gem::Version.new(x) <=> Gem::Version.new(y) }.pop
      end
    end

    result
  end

  # Ok this is dumb. But, it should do what people would expect when writing
  # ensure => latest
  def latest
    'latest'
  end
end
