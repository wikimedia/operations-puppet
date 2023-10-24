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
  Stdlib::Unixpath $basedir         = lookup('profile::aptrepo::staging::public_basedir'),
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
    src_sets => '[$DOMAIN_NETWORKS $MGMT_NETWORKS]',
  }

  nginx::site { 'apt-staging.wikimedia.org':
    content => template('aptrepo/apt-staging.wikimedia.org.conf.erb'),
  }
}
