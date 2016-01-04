# Puppet package provider for `scap3`, a modern deployment system, based on
# previous version of scap. This is mostly a spinoff from the puppet trebuchet
# provider written by Ori Livneh
#
# Copyright 2014 Ori Livneh
# Copyright 2016 Alexandros Kosiaris
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

require 'fileutils'
require 'open-uri'

Puppet::Type.type(:package).provide(
  :scap3,
  :parent => Puppet::Provider::Package
) do

  desc 'Puppet package provider for `Trebuchet`.'

  commands :git_cmd     => '/usr/bin/git'

  has_feature :installable, :uninstallable, :upgradeable

  self::BASE_PATH = '/srv/deployment'

  def self.instances
    []
  end

  def repo
    case @resource[:name]
    when %r{/} then @resource[:name]
    else ([@resource[:name]] * 2).join('/')
    end
  end

  def target_path
    path = File.expand_path(File.join(self.class::BASE_PATH, repo))
    unless path.length > self.class::BASE_PATH.length
      fail Puppet::Error, "Target path '#{path}' is invalid."
    end
    path
  end

  # Convenience wrapper for shelling out to `git`.
  def git(*args)
    git_path = File.join(target_path, '.git')
    git_cmd(*args.unshift('--git-dir', git_path))
  end

  # Return structured information about a particular package or `nil` if
  # it is not installed.
  def query
    tag = git('rev-parse', 'HEAD')
    {
      :ensure => tag.strip
    }
  rescue Puppet::ExecutionFailure
    {
      :ensure => :purged,
      :status => 'missing',
      :name   => @resource[:name]
    }
  end

  # Get the master where to get code from
  # TODO: Actually get the master to clone from instead of hardcoding tin
  def master
    @resource[:source] = 'tin.eqiad.wmnet'
  end

  # Query the deployment server for the SHA1 of the latest tag of
  # a deployment target.
  def latest_sha1
    @cached_sha1 || begin
      source = master
      source = ('http://' + source) unless source.include?('://')
      source.gsub!(%r{/?$}, "/#{repo}/.git/deploy/deploy")
      tag = open(source) { |raw| PSON.load(raw)['tag'] }
      @cached_sha1 = resolve_tag(tag)
    end
  end

  # Get the SHA1 associated with a Git tag.
  def resolve_tag(tag)
    ['origin', target_path].each do |remote|
      sha1 = git('ls-remote', remote, '--tags', "refs/tags/#{tag}")
      return sha1[/^\S+/] unless sha1.nil? || sha1.empty?
    end
  rescue Puppet::ExecutionFailure
    tag
  end

  def latest
    latest_sha1 == query ? resource[:ensure] : latest_sha1
  end

  # Install a package. This ensures that the package is cloned and checked out
  def install
    FileUtils.makedirs(self.class::BASE_PATH)
    source = master
    source = ('http://' + source) unless source.include?('://')
    git('clone', '--quiet', '--no-checkout', "#{source}/#{repo}/.git", target_path)
    git("--work-tree=#{target_path}", 'checkout', '--quiet', 'HEAD')
  end

  # Remove a deployment target. This is an empty method on purpose
  def uninstall
  end

  def update
    install
  end

  # Uninstall a target grain and purge its directory from disk.
  def purge
    uninstall
    Puppet.warning("Deleting #{target_path}")
    FileUtils.rm_rf(target_path)
  end
end
