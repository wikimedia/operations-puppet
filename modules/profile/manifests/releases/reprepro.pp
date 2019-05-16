# server hosting Mediawiki releases
# https://releases.wikimedia.org/mediawiki/
class profile::releases::reprepro(
    $active_server = hiera('releases_server'),
    $passive_server = hiera('releases_server_failover'),
){

  class { '::releases::reprepro': }

  # ssh-based uploads from deployment servers
  ferm::service { 'deployment_package_upload':
      ensure => present,
      proto  => 'tcp',
      port   => 'ssh',
      srange => '$DEPLOYMENT_HOSTS',
  }

    rsync::quickdatacopy { 'srv-org-wikimedia-reprepro':
      ensure      => present,
      auto_sync   => true,
      source_host => $active_server,
      dest_host   => $passive_server,
      module_path => '/srv/org/wikimedia/reprepro',
    }
}
