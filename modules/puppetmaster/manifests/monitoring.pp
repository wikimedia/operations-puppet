# This class collects all alerts and metrics collection monitoring
# for the puppemaster module.

class puppetmaster::monitoring (
    $server_type = $::puppetmaster::server_type,
    $puppet_major_version = undef,
){

    # monitor HTTPS on puppetmasters
    # Note that for frontends both 8140 and 8141 ports will be checked since
    # both will be used
    $puppetmaster_check_uri = $puppet_major_version ? {
        4       => '/puppet/v3',
        default => '/',
    }

    if $server_type == 'frontend' or $server_type == 'standalone' {
        monitoring::service { 'puppetmaster_https':
            description   => 'puppetmaster https',
            check_command => "check_https_port_status!8140!400!${puppetmaster_check_uri}",
        }
    }
    if $server_type == 'frontend' or $server_type == 'backend' {
        monitoring::service { 'puppetmaster_backend_https':
            description   => 'puppetmaster backend https',
            check_command => "check_https_port_status!8141!400!${puppetmaster_check_uri}",
        }
    }

    # Check for unmerged changes that have been sitting for more than one minute.
    # ref: T80100, T83854
    monitoring::icinga::git_merge { 'puppet': }
}
