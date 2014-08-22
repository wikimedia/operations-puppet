# Puppet package provider for `Trebuchet`, a modern, two-phase
# deployment system based on SaltStack.
#
# <https://github.com/trebuchet-deploy/trebuchet>
#
# Copyright 2014 Ori Livneh
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

require 'rubygems'
require 'fileutils'
require 'json'
require 'open-uri'

Puppet::Type.type(:package).provide :trebuchet, :parent => Puppet::Provider::Package do
  desc "Puppet package provider for `Trebuchet`."

  commands :git_cmd    => '/usr/bin/git',
           :salt_cmd   => '/usr/bin/salt-call',
           :status_cmd => '/sbin/status'

  has_feature :installable, :uninstallable, :upgradeable

  self::BASE_PATH = '/srv/deployment'

  def self.instances
    []
  end

  def base
    @resource[:name].split('/').first
  end

  def repo
    @resource[:name].split('/').last
  end

  def qualified_name
    [base, repo].join('/')
  end

  def target_path
    path = File.expand_path(File.join(self.class::BASE_PATH, qualified_name))
    unless path.length > self.class::BASE_PATH.length
        raise Puppet::Error, "Target path '#{path}' is invalid."
    end
    path
  end

  # Convenience wrapper for shelling out to `git`.
  def git(*args)
    git_path = File.join(target_path, '.git')
    git_cmd *args.map(&:split).flatten.unshift('--git-dir', git_path)
  end

  # Convenience wrapper for shelling out to `salt-call`.
  def salt(*args)
    salt_cmd *args.map(&:split).flatten.unshift('--out=json')
  end

  # Make sure that the salt-minion service is running.
  def check_salt_minion_status
    begin
      status = status_cmd('salt-minion')
      raise Puppet::ExecutionFailure unless status.include? 'running'
    rescue Puppet::ExecutionFailure
      fail "Trebuchet requires that the salt-minion service be running."
    end
  end

  # Get the list of deployment targets defined for this minion.
  def targets
    @cached_targets || begin
      check_salt_minion_status
      raw = salt 'grains.get', 'deployment_target'
      @cached_targets = JSON.load(raw).fetch('local', [])
    rescue Puppet::ExecutionFailure
      @cached_targets = []
    end
  end

  # Return structured information about a particular package or `nil` if
  # it is not installed.
  def query
    return nil unless targets.include? base
    begin
      tag = git 'rev-parse', 'HEAD'
      {:ensure => tag.strip}
    rescue Puppet::ExecutionFailure
      {:ensure => :purged, :status => 'missing', :name => @resource[:name]}
    end
  end

  def master
    @resource[:source] || begin
      raw = salt 'grains.get', 'trebuchet_master'
      @resource[:source] = JSON.load(raw).fetch('local')
    end
  end

  # Query the deployment server for the SHA1 of the latest tag of
  # a deployment target.
  def latest_sha1
    @cached_sha1 || begin
      source = master || fail('Unable to determine Trebuchet master.')
      source.prepend('http://') unless source.include? '://'
      source.gsub!(/\/?$/, "/#{qualified_name}/.git/deploy/deploy")
      tag = open(source) { |raw| JSON.load(raw).fetch('tag', nil) }
      @cached_sha1 = resolve_tag(tag)
    end
  end

  # Get the SHA1 associated with a Git tag.
  def resolve_tag(tag)
    begin
      entry = git 'ls-remote', 'origin', "refs/tags/#{tag}"
      entry.split.first.strip || tag
    rescue Puppet::ExecutionFailure
      tag
    end
  end

  def latest
    return latest_sha1 == query ? resource[:ensure] : latest_sha1
  end

  # Install a package. This ensures that the package is listed in the
  # deployment_target grain and that it is checked out.
  def install
    unless targets.include? base
      salt 'grains.append', 'deployment_target', base
    end
    salt 'deploy.fetch', qualified_name
    git 'checkout', '--force', latest_sha1
  end

  # Remove a deployment target. This won't touch the Git repository
  # on disk; it merely unsets the `deployment_target` grain value.
  def uninstall
    salt 'grains.remove', 'deployment_target', base
  end

  def update
    self.install
  end

  # Remove a target from the `deployment_target` grain and purge
  # its directory from disk.
  def purge
    self.uninstall
    FileUtils::rm_rf target_path
  end
end
