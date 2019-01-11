# https://releases.wikimedia.org/blubber
class profile::releases::blubber (
    $active_server = hiera('releases_server'),
    $passive_server = hiera('releases_server_failover'),
){
    file { '/srv/org/wikimedia/releases/blubber':
        ensure => 'directory',
        owner  => 'root',
        group  => 'releasers-blubber',
        mode   => '2775',
    }

    rsync::quickdatacopy { 'srv-org-wikimedia-releases-blubber':
      ensure      => present,
      auto_sync   => true,
      source_host => $active_server,
      dest_host   => $passive_server,
      module_path => '/srv/org/wikimedia/releases/blubber',
    }
}
