# SPDX-License-Identifier: Apache-2.0
#
# @summary Provides a staging repository for CI to build and distribute
#          debian packages.
#
# @param basedir Where reprepro stores config and distribution files
# @param homedir Where to store the GPG keys for signing. GPG keys will be
# .              stored in .gnupg relative to this path.
# @param gpg_user Owner of the GPG keys
# @param gpg_pubring The GPG public keyring for reprepro to use. Will be passed to secret()
# @param gpg_secring The GPG secret keyring for reprepro to use. Will be passed to secret()
class profile::aptrepo::staging (
  Stdlib::Unixpath $basedir         = lookup('profile::aptrepo::staging::basedir'),
  Stdlib::Unixpath $homedir         = lookup('profile::aptrepo::staging::homedir'),
  String           $gpg_user        = lookup('profile::aptrepo::staging::gpg_user'),
  Optional[String] $gpg_pubring     = lookup('profile::aptrepo::staging::gpg_pubring'),
  Optional[String] $gpg_secring     = lookup('profile::aptrepo::staging::gpg_secring'),
) {
  class { 'aptrepo::common':
    homedir     => $homedir,
    basedir     => $basedir,
    gpg_user    => $gpg_user,
    gpg_secring => $gpg_secring,
    gpg_pubring => $gpg_pubring,
  }

  aptrepo::repo { 'staging_apt_repository':
    basedir            => $basedir,
    incomingdir        => 'incoming',
    distributions_file => 'puppet:///modules/aptrepo/distributions-wikimedia-staging',
  }

  firewall::service { 'apt_staging_http':
    proto    => 'tcp',
    port     => [80,443],
    src_sets => ['DOMAIN_NETWORKS', 'MGMT_NETWORKS'],
  }

  nginx::site { 'apt-staging.wikimedia.org':
    content => template('aptrepo/apt-staging.wikimedia.org.conf.erb'),
  }

  systemd::sysuser { 'apt-uploader': }

  file { '/srv/incoming-packages':
    ensure => directory,
    mode   => '0755',
    owner  => 'apt-uploader',
    group  => 'apt-uploader',
  }

  file { '/etc/rsync-apt-auth-secrets':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => secret('apt-staging/rsync-secrets'),
  }

  class { '::rsync::server': }
  rsync::server::module { 'apt-auth':
      ensure         => present,
      comment        => 'Incoming packages for apt-staging.wm.o, from gitlab runners',
      read_only      => 'no',
      path           => '/srv/incoming-packages',
      uid            => 'apt-uploader',
      gid            => 'apt-uploader',
      incoming_chmod => 'D755,F644',
      hosts_allow    => wmflib::role::hosts('gitlab_runner'),
      auto_firewall  => true,
      auth_users     => ['apt-publisher'],
      secrets_file   => '/etc/rsync-apt-auth-secrets',
  }

  ensure_packages(['python3-gitlab'])

  file { '/usr/local/bin/gitlab-package-puller':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/aptrepo/gitlab_package_puller.py',
  }

  file { '/etc/gitlab-puller-auth':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => secret('apt-staging/gitlab-puller-token'),
  }

  profile::auto_restarts::service { 'nginx': }
  profile::auto_restarts::service { 'envoyproxy': }
  profile::auto_restarts::service { 'rsync': }
}
