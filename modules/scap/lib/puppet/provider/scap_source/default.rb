# Puppet default provider for type `scap_source`, which is needed to set up a
# base repository to use with the `scap3` deployment system
#
# Copyright (c) 2016 Giuseppe Lavagetto
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

require 'puppet/provider'
require 'puppet/util/execution'
require 'fileutils'
require 'etc'

Puppet::Type.type(:scap_source).provide(:default) do
  initvars

  def self.default?
    true
  end

  has_command(:git, '/usr/bin/git')
  has_command(:scap, '/usr/bin/scap')

  # Shortand for the repo name
  def repo
    resource[:repository]
  end

  # The origin of the repository
  def origin(repo_name)
    case resource[:origin]
    when :gerrit
      "https://gerrit.wikimedia.org/r/p/#{repo_name}.git"
    when :phabricator
      "https://phabricator.wikimedia.org/source/#{repo_name}.git"
    end
  end

  def repo_name(origin)
    case resource[:origin]
    when :gerrit
      origin.slice! "https://gerrit.wikimedia.org/r/p/"
    when :phabricator
      origin.slice! "https://phabricator.wikimedia.org/source/"
    end
    origin.gsub(/\.git$/, '')
  end

  # The path to install the git clone to
  def repo_path
    if resource[:name].include?(File::SEPARATOR)
      resource[:name]
    else
      File.join(resource[:name], resource[:name])
    end
  end

  def target_path
    path = File.expand_path(File.join(resource[:base_path], repo_path))

    unless path.start_with?(resource[:base_path])
      raise Puppet::Error, "Target path '#{path}' is invalid."
    end
    path
  end

  def deploy_root
    @deploy_root ||= File.dirname(target_path)
  end

  def checkout(name, path)
    umask = 0o002
    file_mode = 0o2775
    unless Dir.exists?(path)
      FileUtils.makedirs path, :mode => file_mode
      FileUtils.chown_R resource[:owner], resource[:group], path
    end
    pwd = Etc.getpwnam(resource[:owner])
    uid = pwd.uid
    gid = pwd.gid
    Puppet::Util.withumask(
      umask) {
      Puppet::Util::Execution.execute(
        [
          self.class.command(:git),
          '-c', 'core.sharedRepository=group',
          'clone',
          '--recurse-submodules',
          origin(name),
          path,
        ],
        :uid => uid,
        :gid => gid,
        :failonfail => true
      )
    }
  end

  def scap_init(path)
    umask = 0o002
    pwd = Etc.getpwnam(resource[:owner])
    uid = pwd.uid
    gid = pwd.gid
    Dir.chdir(path) do
      Puppet::Util.withumask(umask) {
        Puppet::Util::Execution.execute(
          [
            self.class.command(:scap),
            'deploy',
            '--init'
          ],
          :uid => uid,
          :gid => gid,
          :failonfail => true
        )
      }
    end
  end

  def exists?
    # check if the dirs exist; if they do, check
    # if they're a git repo.
    Puppet.debug("Checking existence of #{target_path}")
    return false unless File.directory?(target_path)
    # If the resource needs to be present, let's also check
    # the dir is a git repo
    if resource[:ensure] == :present
      begin
        git('-C', target_path, 'rev-parse', 'HEAD')
      rescue Puppet::ExecutionFailure
        return false
      end
      # Also check that deploy-head is there, and return its value
      deploy_head_exists?
    else
      true
    end
  end

  def deploy_head_exists?
    File.exists?(File.join(target_path, '.git', 'DEPLOY-HEAD'))
  end

  def create
    # Create the parent directory
    unless Dir.exists?(deploy_root)
      Puppet.debug("Creating #{deploy_root}")
      FileUtils.makedirs deploy_root, :mode => 0o755
      FileUtils.chown_R resource[:owner], resource[:group], deploy_root
    end

    # Checkout the main repository, and the scap one too
    unless Dir.exists?(target_path)
      Puppet.debug("Checking out #{repo} into #{target_path}")
      checkout repo, target_path
      Puppet.debug("Repository checked out in #{target_path}")
    end

    if resource[:scap_repository]
      target = File.join(target_path, 'scap')
      checkout resource[:scap_repository], target unless Dir.exists?(target)
    end
    scap_init unless deploy_head_exists?
  end

  def destroy
    Puppet.info("Deleting #{target_path} and all its empty parents")
    dir = target_path
    FileUtils.remove_entry_secure(dir, :force => true)
    loop do
      dir, _ = File.split(dir)
      break if resource[:base_path].include?(dir)
      begin
        Dir.delete(dir)
      rescue Errno::ENOTEMPTY
          Puppet.info("Not removing #{dir} as it's not empty.")
          break
      end
    end
  end

  def repository
    res = git('-C', target_path, 'config', '--get', 'remote.origin.url').chomp
    repo_name(res)
  rescue Puppet::ExecutionFailure
    Puppet.warn('Origin not set or not found')
    raise Puppet::Error, "Could not determine the origin url at #{target_path}"
  end

  def repository=(value)
    git('-C', target_path, 'config', 'remote.origin.url', origin(value))
  end
end
