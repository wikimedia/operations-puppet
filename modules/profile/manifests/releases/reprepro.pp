# server hosting MediaWiki releases
# https://releases.wikimedia.org/mediawiki/
class profile::releases::reprepro(
    Stdlib::Fqdn $active_server = lookup('releases_server'),
    Array[Stdlib::Fqdn] $secondary_servers = lookup('releases_servers_failover'),
){

  class { '::releases::reprepro': }

  # ssh-based uploads from deployment servers
  ferm::service { 'deployment_package_upload':
      ensure => present,
      proto  => 'tcp',
      port   => 'ssh',
      srange => '$DEPLOYMENT_HOSTS',
  }

    $secondary_servers.each |String $secondary_server| {
        rsync::quickdatacopy { "srv-org-wikimedia-reprepro-${secondary_server}":
          ensure      => present,
          auto_sync   => true,
          delete      => true,
          source_host => $active_server,
          dest_host   => $secondary_server,
          module_path => '/srv/org/wikimedia/reprepro',
        }
    }
}
