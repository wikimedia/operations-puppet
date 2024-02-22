# This class collects all alerts and metrics collection monitoring
# for the puppemaster module.

class puppetmaster::monitoring (
    Enum['frontend', 'backend', 'standalone'] $server_type = $::puppetmaster::server_type,
){

    # monitor HTTPS on puppetmasters
    # Note that for frontends both 8140 and 8141 ports will be checked since
    # both will be used
    $puppetmaster_check_uri = '/puppet/v3'

    file { '/usr/local/bin/check_git_needs_merge':
        ensure => present,
        mode   => '0555',
        source => 'puppet:///modules/puppetmaster/check_git_needs_merge.py'
    }

    systemd::timer::job { 'prometheus_puppetmerge_puppet':
        ensure      => present,
        user        => 'root',
        description => 'Prometheus exporter for missing git merges',
        command     => '/usr/local/bin/check_git_needs_merge --basedir /var/lib/git/operations/puppet',
        interval    => {'start' => 'OnUnitInactiveSec', 'interval' => '10m'},
    }

    # Check for unmerged changes that have been sitting for more than one minute.
    # ref: T80100, T83854
    monitoring::icinga::git_merge { 'puppet':
        ensure => absent
    }

    if $server_type == 'frontend' or $server_type == 'standalone' {
        monitoring::service { 'puppetmaster_https':
            ensure        => absent,
            description   => 'puppetmaster https',
            check_command => "check_https_port_status!8140!400!${puppetmaster_check_uri}",
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Puppet#Debugging',
        }
        monitoring::icinga::git_merge { 'labs-private':
            ensure => absent,
            dir    => '/var/lib/git/labs/private/',
        }

        prometheus::blackbox::check::http { "${facts['fqdn']}_https":
            server_name    => $facts['fqdn'],
            path           => $puppetmaster_check_uri,
            port           => 8140,
            status_matches => [400],
            force_tls      => true,
            probe_runbook  => 'https://wikitech.wikimedia.org/wiki/Puppet#Debugging'
        }

        systemd::timer::job { 'prometheus_puppetmerge_labs_private':
            ensure      => present,
            user        => 'root',
            description => 'Prometheus exporter for missing git merges',
            command     => '/usr/local/bin/check_git_needs_merge --basedir /var/lib/git/labs/private/ --name labs_private --branch master',
            interval    => {'start' => 'OnUnitInactiveSec', 'interval' => '10m'},
        }
    }
    if $server_type == 'frontend' or $server_type == 'backend' {
        monitoring::service { 'puppetmaster_backend_https':
            ensure        => absent,
            description   => 'puppetmaster backend https',
            check_command => "check_https_port_status!8141!400!${puppetmaster_check_uri}",
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Puppet#Debugging',
        }

        prometheus::blackbox::check::http { "${facts['fqdn']}_backend_https":
            server_name    => $facts['fqdn'],
            path           => $puppetmaster_check_uri,
            port           => 8141,
            status_matches => [400],
            force_tls      => true,
            probe_runbook  => 'https://wikitech.wikimedia.org/wiki/Puppet#Debugging'
        }

    }
}
