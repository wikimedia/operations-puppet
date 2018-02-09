# = Class: icinga::monitor::checkpaging
#
# Sets up a simple monitoring service to check if paging
# is working properly
class icinga::monitor::checkpaging {
    monitoring::service { 'check_to_check_nagios_paging':
        description    => 'check_to_check_nagios_paging',
        check_command  => 'check_to_check_nagios_paging',
        check_interval => 1,
        retry_interval => 1,
        contact_group  => 'admins',
        critical       => false,
    }

    # temp test for SMS content changes (T185862)
    @monitoring::host { 'foobar.wmflabs.org':
        host_fqdn     => 'foobar.wmflabs.org',
        contact_group => 'test-paging',
    }

    monitoring::service { 'test_service':
        description   => 'TEST SERVICE',
        check_command => 'check_http',
        host          => 'foobar.wmflabs.org',
        contact_group => 'test-paging',
    }
}
