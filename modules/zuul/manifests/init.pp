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
    $gerrit_baseurl = 'https://gerrit.wikimedia.org/r',
    $git_source_repo = 'https://gerrit.wikimedia.org/r/p/integration/zuul.git',
    $git_branch = 'master',
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

  package { $packages:
    ensure => present,
  }

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

  # Craft zuul.conf and zuul-merger.conf, reusing the parameters passed to zuul
  # class.

  file { '/etc/zuul/gearman-logging.conf':
      ensure => present,
      owner  => 'jenkins',
      group  => 'root',
      mode   => '0444',
      source => 'puppet:///modules/zuul/gearman-logging.conf',
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

}
