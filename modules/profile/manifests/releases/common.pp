class profile::releases::common{

    # T205037
    $motd_ensure = mediawiki::state('primary_dc') ? {
        $::site => 'absent',
        default => 'present',
    }

    motd::script { 'rsync_source_warning':
        ensure   => $motd_ensure,
        priority => 1,
        content  => template('role/releases/rsync_source_warning.motd.erb'),
    }

    base::service_auto_restart { 'rsync': }
}
