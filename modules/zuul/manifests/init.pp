# OpenStack zuul
#
# A Jenkins/Gerrit gateway written in python. This is a drop in replacement
# for Jenkins "Gerrit Trigger" plugin.
#
# Lamely copied from openstack-ci/openstack-ci-puppet repository, replaced
# vcsrepo by our git::clone class.
#

# == Class: zuul
#
# Install Zuul from source
#
# === Parameters
#
# $git_source_repo : git repository to clone from
# $git_source_branch : branch on the repository to pull
#
class zuul (
    $git_source_repo = 'https://gerrit.wikimedia.org/r/p/integration/zuul.git',
    $git_source_branch = 'master',
) {

  include zuul::user

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

    'python-pip',
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
    branch    => $git_source_branch,
  }

  exec { 'install_zuul':
    # Make sure to install without downloading from pypi
    command     => 'python setup.py install',
    env         => 'HTTP_PROXY=. HTTPS_PROXY=.',
    cwd         => $zuul_source_dir,
    path        => '/bin:/usr/bin',
    refreshonly => true,
    subscribe   => Git::Clone['integration/zuul'],
    require     => [
      Package['python-pip'],
      Package['python-setuptools'],
    ],
  }

  file { '/etc/zuul':
    ensure => directory,
  }

  file { '/var/log/zuul':
    ensure  => directory,
    owner   => 'zuul',
  }

  file { '/var/lib/zuul':
    ensure  => directory,
    owner   => 'zuul',
  }

}
