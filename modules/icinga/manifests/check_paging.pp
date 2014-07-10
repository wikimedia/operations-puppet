
class icinga::check_paging {

    require icinga::packages

    file {'/usr/lib/nagios/plugins/check_to_check_nagios_paging':
        source => 'puppet:///files/icinga/check_to_check_nagios_paging',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    monitor_service { 'check_to_check_nagios_paging':
        description           => 'check_to_check_nagios_paging',
        check_command         => 'check_to_check_nagios_paging',
        normal_check_interval => 1,
        retry_check_interval  => 1,
        contact_group         => 'pager_testing',
        critical              => false
    }
}

