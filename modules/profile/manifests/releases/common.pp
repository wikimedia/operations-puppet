class profile::releases::common{

    # T205037
    $motd_ensure = mediawiki::state('primary_dc') ? {
        $::site => 'present',
        default => 'absent',
    }

    motd::script { 'rsync_source_warning':
        ensure   => $motd_ensure,
        priority => 1,
        content  => template('role/mediawiki_maintenance/inactive.motd.erb'),
    }
}
