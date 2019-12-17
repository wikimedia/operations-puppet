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
    Stdlib::Host $private_git_peer,
    String $nb_token,
    Stdlib::HTTPSUrl $nb_api,
) {

  $public_repo = '/srv/homer/public'
  $private_repo = '/srv/homer/private'
  $output_dir = '/srv/homer/output'

  file { '/srv/homer':
      ensure  => directory,
      owner   => 'root',
      group   => 'ops',
      mode    => '0550',
      require => Scap::Target['homer/deploy'],
  }

  file { $output_dir:
      ensure  => directory,
      owner   => 'root',
      group   => 'ops',
      mode    => '0770',
      require => File['/srv/homer'],
  }

# Clone the public data
  git::clone { 'operations/homer/public':
      ensure    => 'latest',
      directory => $public_repo,
      owner     => 'root',
      group     => 'ops',
      mode      => '0440',
      require   => File['/srv/homer'],
  }

  file { '/etc/homer':
      ensure  => directory,
      owner   => 'root',
      group   => 'ops',
      mode    => '0550',
      require => Scap::Target['homer/deploy'],
  }

  file { '/etc/homer/config.yaml':
      ensure  => present,
      content => template('homer/config.yaml.erb'),
      owner   => 'root',
      group   => 'ops',
      mode    => '0440',
      require => File['/etc/homer'],
  }

  file { '/usr/local/bin/homer':
      ensure  => present,
      owner   => 'root',
      group   => 'ops',
      mode    => '0550',
      source  => 'puppet:///modules/homer/homer.sh',
      require => Scap::Target['homer/deploy'],
  }

  # Set git config and hooks for the private repo
  $private_repo_git_dir = "${private_repo}/.git"
  file { "${private_repo_git_dir}/config":
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('homer/private-git/config.erb'),
  }

  file { "${private_repo_git_dir}/hooks":
      ensure => present,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
      source => 'puppet:///modules/homer/private-git/hooks',
  }
}
