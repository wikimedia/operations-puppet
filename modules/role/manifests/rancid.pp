# Really Awful Notorious CIsco config Differ
class role::rancid {

    system::role { 'rancid':
        description => 'Really Awful Notorious CIsco config Differ (sp)'
    }

    include ::standard
    include ::rancid
    include ::profile::backup::host

    backup::set { 'rancid': }

    rsync::quickdatacopy { 'var-lib-rancid':
      ensure      => present,
      auto_sync   => false,
      source_host => 'netmon1002.wikimedia.org',
      dest_host   => 'netmon2001.wikimedia.org',
      module_path => '/var/lib/rancid',
    }

    $active_server = hiera('netmon_server', 'netmon1002.wikimedia.org')

    class { '::rancid':
        active_server => $active_server,
    }
}
