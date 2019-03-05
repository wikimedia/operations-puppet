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
        notes_url      => 'https://phabricator.wikimedia.org/tag/monitoring/',
    }
}
