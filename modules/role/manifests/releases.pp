# == Class: role::releases
#
# Sets up a machine to generate and host releases of software
class role::releases {

    system::role { 'releases':
        ensure      => 'present',
        description => 'Wikimedia Software Releases Server',
    }

    include ::standard
    include ::base::firewall
    include ::profile::backup::host
    include ::profile::releases::mediawiki
    include ::profile::releases::reprepro

    $active_server = hiera('releases_server', 'releases1001.eqiad.wmnet')
    $passive_server = hiera('releases_server_failover', 'releases2001.codfw.wmnet')

    rsync::quickdatacopy { 'srv-org-wikimedia-releases':
      ensure      => present,
      source_host => $active_server,
      dest_host   => $passive_server,
      module_path => '/srv/org/wikimedia/releases',
    }

    rsync::quickdatacopy { 'srv-org-wikimedia-reprepro':
      ensure      => present,
      source_host => $active_server,
      dest_host   => $passive_server
      module_path => '/srv/org/wikimedia/reprepro',
    }
}
