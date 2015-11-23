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

require 'fileutils'
require 'open-uri'

Puppet::Type.type(:package).provide(
  :trebuchet,
  :parent => Puppet::Provider::Package
) do

  desc 'Puppet package provider for `Trebuchet`.'

  commands :git_cmd     => '/usr/bin/git',
           :salt_cmd    => '/usr/bin/salt-call'

  has_feature :installable, :uninstallable, :upgradeable

  self::BASE_PATH = '/srv/deployment'

  def self.instances
    []
  end

  def repo
    case @resource[:name]
    when /\// then @resource[:name]
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

  # Convenience wrapper for shelling out to `salt-call`.
  def salt(*args)
    salt_cmd(*args.unshift('--log-level=quiet', '--out=json'))
  end

  # Synchronize local state with Salt master.
  def salt_refresh!
    salt('saltutil.sync_all')
    salt('saltutil.refresh_pillar')
  end

  # Make sure that the salt-minion service is running.
  def check_salt_minion_status
    raw = salt('--local', 'service.status', 'salt-minion')
    minion_running = PSON.load(raw).fetch('local', false)
    fail Puppet::ExecutionFailure unless minion_running
  rescue Puppet::ExecutionFailure
    raise Puppet::ExecutionFailure, <<-END
      The Trebuchet package provider requires that the salt-minion
      service be running.
    END
  end

  # Get the list of deployment targets defined for this minion.
  def targets
    @cached_targets || begin
      check_salt_minion_status
      raw = salt('--local', 'grains.get', 'deployment_target')
      @cached_targets = PSON.load(raw).fetch('local', [])
    rescue Puppet::ExecutionFailure
      @cached_targets = []
    end
  end

  # Return structured information about a particular package or `nil` if
  # it is not installed.
  def query
    return nil unless targets.include?(repo)

    begin
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
  end

  def master
    @resource[:source] || begin
      raw = salt('--local', 'grains.get', 'trebuchet_master')
      master = PSON.load(raw)['local']
      if master.nil? || master.empty?
        fail Puppet::Error, <<-END
          Unable to determine Trebuchet master, because neither the `source`
          parameter nor the `trebuchet_master` grain is set.
        END
      end
      @resource[:source] = master
    end
  end

  # Query the deployment server for the SHA1 of the latest tag of
  # a deployment target.
  def latest_sha1
    @cached_sha1 || begin
      source = master
      source = ('http://' + source) unless source.include?('://')
      source.gsub!(/\/?$/, "/#{repo}/.git/deploy/deploy")
      tag = open(source) { |raw| PSON.load(raw)['tag'] }
      @cached_sha1 = resolve_tag(tag) || tag
    end
  end

  # Get the SHA1 associated with a Git tag.
  def resolve_tag(tag)
    ['origin', target_path].each do |remote|
      sha1 = git('ls-remote', remote, '--tags', "refs/tags/#{tag}")
      return sha1[/^\S+/] unless sha1.nil? || sha1.empty?
    end
  rescue Puppet::ExecutionFailure
  end

  def latest
    latest_sha1 == query ? resource[:ensure] : latest_sha1
  end

  # Install a package. This ensures that the package is listed in the
  # deployment_target grain and that it is checked out.
  def install
    unless targets.include?(repo)
      salt('grains.append', 'deployment_target', repo)
      salt_refresh!
    end
    salt('deploy.fetch', repo)
    salt('deploy.checkout', repo)
  end

  # Remove a deployment target. This won't touch the Git repository
  # on disk; it merely unsets the `deployment_target` grain value.
  def uninstall
    salt('grains.remove', 'deployment_target', repo)
    salt_refresh!
  end

  def update
    install
  end

  # Remove a target from the `deployment_target` grain and purge
  # its directory from disk.
  def purge
    uninstall
    Puppet.warning("Deleting #{target_path}")
    FileUtils.rm_rf(target_path)
  end
end
