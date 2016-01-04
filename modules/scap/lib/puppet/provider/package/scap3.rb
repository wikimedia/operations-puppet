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

require 'etc'
require 'fileutils'

Puppet::Type.type(:package).provide(
  :scap3,
  :parent => Puppet::Provider::Package
) do
  desc 'Puppet package provider for `scap3`.'

  has_feature :installable, :uninstallable, :package_settings

  commands :deploy_local => '/usr/bin/deploy-local'

  BASE_PATH = '/srv/deployment'

  # This provider currently maintains no internal resources.
  #
  def self.instances
    []
  end

  # Reads the current owner of the deploy root or, if the package hasn't been
  # installed yet, the owner specified for the resource, or 'root'.
  #
  def package_settings
    if File.exists?(deploy_root)
      owner = Etc.getpwuid(File.stat(deploy_root).uid).name
    else
      settings = resource[:package_settings] || {}
      owner = settings['owner'] || 'root'
    end

    { 'owner' => owner }
  end

  # Checks whether the desired deploy root owner is the same as the current
  # one.
  #
  def package_settings_insync?(goal, have)
    goal['owner'] == have['owner']
  end

  # Sets a new deploy root owner by recursively chown'ing the directory.
  #
  def package_settings=(goal)
    FileUtils.chown_R(goal['owner'], nil, deploy_root)
  end

  # Performs project installation via scap3's deploy-local command. The
  # target's parent directory is created if it doesn't already exist, but the
  # cache and final directory creation is left up to scap.
  #
  def install
    unless Dir.exists?(deploy_root)
      FileUtils.makedirs(deploy_root)
      FileUtils.chown_R(package_settings['owner'], nil, deploy_root)
    end

    uid = Etc.getpwnam(package_settings['owner']).uid
    cmd = [self.class.command(:deploy_local), '--repo', repo, '-D', 'log_json:False']

    execute(cmd, uid: uid)
  end

  # Performs project uninstallation by removing the deploy root directory.
  #
  def uninstall
    Puppet.warning("Deleting #{deploy_root}")
    FileUtils.rm_rf(deploy_root)
  end

  private

  def deploy_root
    @deploy_root ||= File.dirname(target_path)
  end

  def deploy_user
    settings = resource[:package_settings] || {}
    settings['owner'] || 'root'
  end

  def repo
    resource[:name]
  end

  def repo_path
    if repo.include?('/')
      repo
    else
      [repo, repo].join('/')
    end
  end

  def target_path
    path = File.expand_path(File.join(BASE_PATH, repo_path))

    unless path.start_with?(BASE_PATH)
      raise Puppet::Error, "Target path '#{path}' is invalid."
    end

    path
  end
end
