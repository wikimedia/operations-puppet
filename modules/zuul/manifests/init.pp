# OpenStack zuul
#
# A Jenkins/Gerrit gateway written in python. This is a drop in replacement
# for Jenkins "Gerrit Trigger" plugin.
#
# Lamely copied from openstack-ci/openstack-ci-puppet repository, replaced
# vcsrepo by our git::clone class.
#

# == Class: zuul
class zuul (
    $jenkins_server,
    $jenkins_user,
    $jenkins_apikey,
    $gearman_server,
    $gearman_server_start,
    $gerrit_server,
    $gerrit_user,
    $gerrit_baseurl = 'https://gerrit.wikimedia.org/r',
    $url_pattern,
    $status_url = "https://${::fqdn}/zuul/status",
    $zuul_url = 'git://zuul.eqiad.wmnet',
    $git_source_repo = 'https://gerrit.wikimedia.org/r/p/integration/zuul.git',
    $git_branch = 'master',
    $git_dir = '/var/lib/zuul/git',
    $statsd_host = '',
    $git_email = "zuul-merger@${::hostname}",
    $git_name = 'Wikimedia Zuul Merger',
) {

  # Dependencies as mentionned in zuul:tools/pip-requires
  $packages = [
    'python-yaml',
    'python-webob',
    'python-daemon',
    'python-lockfile',
    'python-paramiko',
    'python-jenkins',
    'python-paste',

    # GitPython at least 0.3.2RC1 which is neither in Lucid nor in Precise
    # We had to backport it and its dependencies from Quantal:
    'python-git',
    'python-gitdb',
    'python-async',
    'python-smmap',

    'python-extras',  # backported in Precise (bug 47122)
    'python-statsd',

    'python-setuptools',
    'python-voluptuous',

    # For Zuul post v1.3.0
    'python-pbr',
    'python-gear',
    'python-apscheduler',

    'python-babel',
    'python-prettytable',
  ]

  ensure_packages($packages)

  # Used to be in /var/lib/git/zuul but /var/lib/git can be used
  # to replicate git bare repositories.
  $zuul_source_dir = '/usr/local/src/zuul'

  git::clone { 'integration/zuul':
    ensure    => present,
    directory => $zuul_source_dir,
    origin    => $git_source_repo,
    branch    => $git_branch,
  }

  exec { 'install_zuul':
    # Make sure to install without downloading from pypi
    command     => 'python setup.py easy_install --allow-hosts=None .',
    cwd         => $zuul_source_dir,
    path        => '/bin:/usr/bin',
    refreshonly => true,
    subscribe   => Git::Clone['integration/zuul'],
    require     => [
      Package['python-setuptools'],
    ],
  }

  file { '/etc/zuul':
    ensure => directory,
  }

  # TODO: We should put in  notify either Service['zuul'] or Exec['zuul-reload']
  #       at some point, but that still has some problems.
  file { '/etc/zuul/zuul.conf':
    ensure  => present,
    owner   => 'jenkins',
    mode    => '0400',
    content => template('zuul/zuul.conf.erb'),
    notify  => Exec['craft public zuul conf'],
    require => [
      File['/etc/zuul'],
      Package['jenkins'],
    ],
  }

  file { '/etc/zuul/gearman-logging.conf':
      ensure => present,
      owner  => 'jenkins',
      group  => 'root',
      mode   => '0444',
      source => 'puppet:///modules/zuul/gearman-logging.conf',
  }

  # Additionally provide a publicly readeable configuration file
  exec { 'craft public zuul conf':
    cwd         => '/etc/zuul/',
    command     => '/bin/sed "s/apikey=.*/apikey=<obfuscacated>/" /etc/zuul/zuul.conf > /etc/zuul/public.conf',
    refreshonly => true,
  }

  file { '/var/log/zuul':
    ensure  => directory,
    owner   => 'jenkins',
    require => Package['jenkins'],
  }

  file { '/var/lib/zuul':
    ensure  => directory,
    owner   => 'jenkins',
    require => Package['jenkins'],
  }

  file { $git_dir:
    ensure  => directory,
    owner   => 'jenkins',
    require => Package['jenkins'],
  }

  file { '/etc/default/zuul':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('zuul/zuul.default.erb'),
  }

}
