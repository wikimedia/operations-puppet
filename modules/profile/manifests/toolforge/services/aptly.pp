class profile::toolforge::services::aptly(
    $active_node = lookup('profile::toolforge::services::active_node'),
    $standby_node = lookup('profile::toolforge::services::standby_node'),
) {
    aptly::repo { 'stretch-tools':
        publish      => true,
    }
    aptly::repo { 'jessie-tools':
        publish      => true,
    }

    # make sure we have a backup server ready to take over
    rsync::quickdatacopy { 'aptly-sync':
        ensure      => present,
        auto_sync   => true,
        source_host => $active_node,
        dest_host   => $standby_node,
        module_path => '/srv/packages',
    }
}
