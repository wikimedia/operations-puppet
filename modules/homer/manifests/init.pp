# SPDX-License-Identifier: Apache-2.0
# == Class: homer
#
# This class installs & manages Homer, a network configuration management tool
#
# == Parameters:
# - $private_git_peer: FQDN or IP of the private repo peer to sync to at each commit.
# - $nb_token: Token to use to authenticate to Netbox
# - $nb_api: Netbox URL
#
class homer(
    Array[Stdlib::Host] $private_git_peers,
    String $nb_token,
    Stdlib::HTTPSUrl $nb_api,
    String $homer_password,
) {

  $public_repo = '/srv/homer/public'
  $private_repo = '/srv/homer/private'
  $output_dir = '/srv/homer/output'

  file { '/srv/homer':
      ensure => directory,
      group  => 'ops',
      mode   => '0550',
  }

  file { $output_dir:
      ensure  => directory,
      group   => 'ops',
      mode    => '0770',
      require => File['/srv/homer'],
  }

  if debian::codename::ge('trixie') {
      # Clone the public data
      git::clone { 'operations/homer/public':
          ensure    => 'latest',
          directory => $public_repo,
          owner     => 'root',
          group     => 'ops',
          require   => File['/srv/homer'],
      }

      # Clone the private data from the first $private_git_peers host
      # The data must be present on the other peer, the current puppetization doesn't
      # cover the case of a fresh start without data in either peer hosts.
      git::clone { 'homer_private_repo':
          ensure                => 'present',
          origin                => "ssh://${private_git_peers[0]}/srv/homer/private",
          directory             => $private_repo,
          environment_variables => ['SSH_AUTH_SOCK=/run/keyholder/proxy.sock'],
          owner                 => 'root',
          group                 => 'ops',
          require               => File['/srv/homer'],
      }
  } else {
      # Clone the public data
      git::clone { 'operations/homer/public':
          ensure    => 'latest',
          directory => $public_repo,
          owner     => 'root',
          group     => 'ops',
          mode      => '0440',
          require   => File['/srv/homer'],
      }

      # Clone the private data from the first $private_git_peers host
      # The data must be present on the other peer, the current puppetization doesn't
      # cover the case of a fresh start without data in either peer hosts.
      git::clone { 'homer_private_repo':
          ensure                => 'present',
          origin                => "ssh://${private_git_peers[0]}/srv/homer/private",
          directory             => $private_repo,
          environment_variables => ['SSH_AUTH_SOCK=/run/keyholder/proxy.sock'],
          owner                 => 'root',
          group                 => 'ops',
          mode                  => '0440',
          require               => File['/srv/homer'],
      }
  }

  file { '/etc/homer':
      ensure => directory,
      group  => 'ops',
      mode   => '0550',
  }

  file { '/etc/homer/config.yaml':
      ensure  => present,
      content => template('homer/config.yaml.erb'),
      group   => 'ops',
      mode    => '0440',
      require => File['/etc/homer'],
  }

  file { '/usr/local/bin/homer':
      ensure => present,
      group  => 'ops',
      mode   => '0550',
      source => 'puppet:///modules/homer/homer.sh',
  }

  # Set git config and hooks for the private repo
  $private_repo_git_dir = "${private_repo}/.git"
  file { "${private_repo_git_dir}/config":
      ensure  => present,
      mode    => '0644',
      content => template('homer/private-git/config.erb'),
      require => Git::Clone['homer_private_repo'],
  }

  file { "${private_repo_git_dir}/hooks":
      ensure  => directory,
      recurse => 'remote',
      mode    => '0755',
      source  => 'puppet:///modules/homer/private-git/hooks',
      require => Git::Clone['homer_private_repo'],
  }

  file { "${private_repo_git_dir}/hooks/post-commit":
      ensure  => file,
      mode    => '0755',
      content => template('homer/private-git/hooks/post-commit.erb'),
      require => File["${private_repo_git_dir}/hooks"],
  }
}
