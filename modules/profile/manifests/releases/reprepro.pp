# server hosting MediaWiki releases
# https://releases.wikimedia.org/mediawiki/
class profile::releases::reprepro(
    Stdlib::Fqdn $primary_server = lookup('releases_server'),
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

    $all_secondary_servers = join($secondary_servers, ' ')
    $all_releases_servers = "${primary_server} ${all_secondary_servers}"
    $all_releases_servers_array = split($all_releases_servers, ' ')

    $all_releases_servers_array.each |String $releases_server| {
        rsync::quickdatacopy { "srv-org-wikimedia-reprepro-${releases_server}":
          ensure      => present,
          auto_sync   => true,
          delete      => true,
          source_host => $primary_server,
          dest_host   => $releases_server,
          module_path => '/srv/org/wikimedia/reprepro',
        }
    }
}
