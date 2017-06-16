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

  has_feature :installable, :uninstallable, :install_options

  commands :scap => '/usr/bin/scap', :git => '/usr/bin/git'

  BASE_PATH = '/srv/deployment'

  # This provider currently maintains no internal resources.
  #
  def self.instances
    []
  end

  # Performs project installation via scap3's deploy-local command. The
  # target's parent directory is created if it doesn't already exist, but the
  # cache and final directory creation is left up to scap.
  #
  def install
    unless Dir.exists?(deploy_root)
      FileUtils.makedirs(deploy_root)
    end

    FileUtils.chown_R(deploy_user, nil, deploy_root)

    FileUtils.cd(deploy_root)

    Puppet.debug "scap pkg [#{repo_path}] root=#{deploy_root}, user=#{deploy_user}"

    uid = Etc.getpwnam(deploy_user).uid

    execute([self.class.command(:scap), 'deploy-local', '--repo', repo_path, '-D', 'log_json:False'],
            :uid => uid, :failonfail => true)
  end

  def install_options
    resource[:install_options]
  end

  # extract the value given for the first matching named key within
  # any hash passed to the package resource's install_options parameter.
  # this is used to pass the 'owner' argument so that the deployment root
  # can be owned by the right user. This is necessary in for deploy-local, as
  # it does not typically run as root.
  #
  # Note: package_settings would be a cleaner solution for this, however,
  # that feature requires puppet >= 3.5 and we must support version 3.4
  def install_option(key, default = nil)
    return unless install_options
    install_options.each do |val|
      case val
      when Hash
        if val[key]
          return val[key]
        end
      end
    end
    default
  end

  # Queries the current state of a scap3 managed package. The package is
  # assumed to be installed if `git tag --points-at HEAD` succeeds. The exact
  # version that's returned will be the latest tag created by scap.
  #
  # Once we have some sort of `--diff` functionality in `deploy-local`, we
  # might be able to improve this.
  #
  def query
    result = { :ensure => :installed, :name => resource[:name] }

    begin
      sha1 = git('-C', target_path, 'tag', '--points-at', 'HEAD').strip
      result[:ensure] = sha1 unless sha1.empty?
    rescue Puppet::ExecutionFailure
      result[:ensure] = :absent
    end

    result
  end

  # Performs project uninstallation by removing the deploy root directory.
  def uninstall
    Puppet.warning("Deleting #{deploy_root}")
    FileUtils.rm_rf(deploy_root)
  end

  private

  # top level directory of this package.
  # (the first subdirectory below /srv/deployment)
  def deploy_root
    @deploy_root ||= File.dirname(target_path)
  end

  def deploy_user
    @deploy_user ||= install_option('owner', 'root')
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
