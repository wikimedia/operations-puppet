# This class collects all alerts and metrics collection monitoring
# for the puppemaster module.

class puppetmaster::monitoring ($server_type = $::puppetmaster::server_type) {

    # monitor HTTPS on puppetmasters
    # Note that for frontends both 8140 and 8141 ports will be checked since
    # both will be used
    if $server_type == 'frontend' or $server_type == 'standalone' {
        monitoring::service { 'puppetmaster_https':
            description   => 'puppetmaster https',
            check_command => 'check_https_port_status!8140!400',
        }
    }
    if $server_type == 'frontend' or $server_type == 'backend' {
        monitoring::service { 'puppetmaster_backend_https':
            description   => 'puppetmaster backend https',
            check_command => 'check_https_port_status!8141!400',
        }
    }

    # Check for unmerged changes that have been sitting for more than one minute.
    # ref: T80100, T83854
    monitoring::icinga::git_merge { 'puppet': }
}
