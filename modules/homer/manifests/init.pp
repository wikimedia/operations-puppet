# == Class: homer
#
# This class installs & manages Homer, a network configuration management tool
#
class homer(){

  file { '/srv/homer':
      ensure  => directory,
      owner   => 'root',
      group   => 'ops',
      mode    => '0550',
      require => Scap::Target['homer/deploy'],
  }

  file { '/srv/homer/output':
      ensure  => directory,
      owner   => 'root',
      group   => 'ops',
      mode    => '0770',
      require => File['/srv/homer'],
  }

# Clone the public data
  git::clone { 'operations/homer/public':
      ensure    => 'latest',
      directory => '/srv/homer/public',
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
      source  => 'puppet:///modules/homer/config.yaml',
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

}
