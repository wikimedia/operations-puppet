class profile::mediawiki::php::restarts(
    Boolean $has_lvs = lookup('has_lvs'),
    Wmflib::Ensure $ensure=lookup('profile::mediawiki::php::restarts::ensure'),
    Integer $opcache_limit=lookup('profile::mediawiki::php::restarts::opcache_limit'),
    Hash $pools = lookup('profile::lvs::realserver::pools', {'default_value' => {}}),
) {
    require profile::mediawiki::php
    require profile::mediawiki::php::monitoring

    # This profile shouldn't be included unless php-fpm is active
    unless $::profile::mediawiki::php::enable_fpm {
        fail('Profile mediawiki::php::restarts can only be included if FPM is enabled')
    }

    # Check, then restart php-fpm if needed.
    # This implicitly depends on the other MediaWiki/PHP profiles
    # Setting $opcache_limit to 0 will replace the script with a noop and thus disable restarts
    if $opcache_limit == 0 {
        file { '/usr/local/sbin/check-and-restart-php':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            content => "#!/bin/sh\nexit 0"
        }
    } else {
            file { '/usr/local/sbin/check-and-restart-php':
                ensure => $ensure,
                owner  => 'root',
                group  => 'root',
                mode   => '0555',
                source => 'puppet:///modules/profile/mediawiki/php/php-check-and-restart.sh',
            }
    }
    if $has_lvs {
        $nodes_by_pool = $pools.keys().map | $pool | { {$pool => wmflib::service::get_pool_nodes($pool)} }.reduce({}) |$m, $val| { $m.merge($val) }
    }

    $php_versions = $profile::mediawiki::php::php_versions
    $php_versions.each |$php_version| {
        # Service name
        $service = php::fpm::programname($php_version)


        # If the server is part of a load-balanced cluster, we need to coordinate the systemd timers across
        # the cluster
        if $has_lvs {
            # All the nodes we have to orchestrate with
            $all_nodes = $nodes_by_pool.values().flatten().unique()
        }
        else {
            # We need to add the php restart script here.
            # We don't actually define any pool so the script will just
            # be a wrapper around sysctl
            conftool::scripts::safe_service_restart{ $service:
                lvs_pools       => [],
            }
            $all_nodes = []
        }

        if member($all_nodes, $::fqdn) {
            $times = cron_splay($all_nodes, 'daily', "${service}-opcache-restarts")
        }
        else {
            $times =  { 'OnCalendar' => sprintf('*-*-* %02d:00:00', fqdn_rand(24)) }
        }

        # Using a systemd timer should ensure we can track if the job fails
        systemd::timer::job { "${service}_check_restart":
            ensure            => $ensure,
            description       => 'Cronjob to check the status of the opcache space on PHP7, and restart the service if needed',
            command           => "/usr/local/sbin/check-and-restart-php ${service} ${opcache_limit}",
            interval          => {'start' => 'OnCalendar', 'interval' => $times['OnCalendar']},
            user              => 'root',
            logfile_basedir   => '/var/log/mediawiki',
            syslog_identifier => "${service}_check_restart"
        }
    }
    # Add a script that restarts all php-fpm versions for scap.
    # It needs to run as root and we'll need to grant the permissions to run it
    # to users in the deployment group as well as to mwdeploy.
    $all_php_fpms = $php_versions.map |$v| {
        php::fpm::programname($v)
    }.join(' ')
    $cmdpath = '/usr/local/sbin/restart-php-fpm-all'
    if $has_lvs {
        # find the pools we're attached to using the default php version for simplicity
        $prgname = php::fpm::programname($php_versions[0])
        $all_php_fpm_pools = $pools.filter |$pool, $services| { $prgname in $services['services'] }.map |$el| { $el[0] }.join(' ')
        # Safeguard: act on 10% of the nodes at max, or 1 otherwise.
        $smallest_pool_size = min(*$nodes_by_pool.values.map |$p| { $p.length })
        $max_concurrency = max(floor($smallest_pool_size * 0.1), 1)
        file { $cmdpath:
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0500',
            content => template('profile/mediawiki/restart-php-fpm-all.sh.erb'),
        }
    } else {
        # No loadbalancer, just restart the services
        file { $cmdpath:
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0500',
            content => "#!/bin/bash\nfor svc in ${all_php_fpm_pools}; do systemctl restart \$svc; done"
        }
    }

}
