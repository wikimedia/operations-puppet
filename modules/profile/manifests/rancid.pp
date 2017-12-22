# Really Awful Notorious CIsco config Differ
class profile::rancid (
    $active_server = hiera('netmon_server')
){

    class { '::rancid':
        active_server => $active_server,
    }

    backup::set { 'rancid': }

    rsync::quickdatacopy { 'var-lib-rancid':
      ensure      => present,
      auto_sync   => false,
      source_host => 'netmon2001.wikimedia.org',
      dest_host   => 'netmon1002.wikimedia.org',
      module_path => '/var/lib/rancid',
    }
}
