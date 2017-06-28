# server hosting Mediawiki releases
# https://releases.wikimedia.org/mediawiki/
class profile::releases::reprepro {

  class { '::releases::reprepro': }

  # ssh-based uploads from deployment servers
  ferm::rule { 'deployment_package_upload':
      ensure => present,
      rule   => 'proto tcp dport ssh saddr $DEPLOYMENT_HOSTS ACCEPT;',
  }
}
