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

    # Service name
    $service = $::profile::mediawiki::php::fpm_programname
    # Check, then restart php-fpm if needed.
    # This implicitly depends on the other MediaWiki/PHP profiles
    file { '/usr/local/sbin/check-and-restart-php':
        ensure => $ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/mediawiki/php/php-check-and-restart.sh',
    }


    # If the server is part of a load-balanced cluster, we need to coordinate the cronjobs across
    # the cluster
    if $has_lvs {
        # All the nodes we have to orchestrate with
        $all_nodes = $pools.keys().map | $pool | { wmflib::service::get_pool_nodes($pool) }.flatten().unique()
    }
    else {
        # We need to add the php restart script here.
        # We don't actually define any pool so the script will just
        # be a wrapper around sysctl
        conftool::scripts::safe_service_restart{ $service:
            lvs_pools       => [],
            lvs_services    => {},
            lvs_class_hosts => {}
        }
        $all_nodes = []
    }

    if member($all_nodes, $::fqdn) {
        $times = cron_splay($all_nodes, 'daily', "${service}-opcache-restarts")
        $hour = sprintf('%02d', $times['hour'])
        $minute = sprintf('%02d', $times['minute'])
        $systemd_timer_interval = sprintf('*-*-* %02d:%02d:00',$times['hour'], $times['minute'])
    }
    else {
        $systemd_timer_interval = sprintf('*-*-* %02d:00:00', fqdn_rand(24))
    }

    # Using a systemd timer should ensure we can track if the job fails
    systemd::timer::job { "${service}_check_restart":
        description       => 'Cronjob to check the status of the opcache space on PHP7, and restart the service if needed',
        command           => "/usr/local/sbin/check-and-restart-php ${service} ${opcache_limit}",
        interval          => {'start' => 'OnCalendar', 'interval' => $systemd_timer_interval},
        user              => 'root',
        logfile_basedir   => '/var/log/mediawiki',
        syslog_identifier => "${service}_check_restart"
    }
}
