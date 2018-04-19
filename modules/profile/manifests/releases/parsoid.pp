# server hosting (an archive of) Parsoid releases
# https://releases.wikimedia.org/parsoid/
class profile::releases::parsoid (
    $active_server = hiera('releases_server'),
    $passive_server = hiera('releases_server_failover'),
){
    file { '/srv/org/wikimedia/releases/parsoid':
        ensure => 'directory',
        owner  => 'root',
        group  => 'releasers-parsoid',
        mode   => '2775',
    }

    rsync::quickdatacopy { 'srv-org-wikimedia-releases-parsoid':
      ensure      => present,
      source_host => $active_server,
      dest_host   => $passive_server,
      module_path => '/srv/org/wikimedia/releases/parsoid',
      auto_sync   => true,
    }

}
