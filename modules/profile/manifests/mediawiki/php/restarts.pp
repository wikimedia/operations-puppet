class profile::mediawiki::php::restarts(
    Wmflib::Ensure $ensure=lookup('profile::mediawiki::php::restarts::ensure'),
    Integer $opcache_limit=lookup('profile::mediawiki::php::restarts::opcache_limit'),
) {
    # realserver gives us the pools the server is included in, plus the lvs configuration
    require profile::lvs::realserver
    require profile::mediawiki::php
    require profile::mediawiki::php::monitoring

    # This profile shouldn't be included unless php-fpm is active
    unless $::profile::mediawiki::php::enable_fpm {
        fail('Profile mediawiki::php::restarts can only be included if FPM is enabled')
    }

    $pools = keys($::profile::lvs::realserver::pools)
    # All the nodes we have to orchestrate with
    $all_nodes = profile::lvs_pool_nodes($pools, $::lvs::configuration::lvs_services)
    # Service name
    $service = $::profile::mediawiki::php::fpm_programname
    # Check, then restart php-fpm if needed.
    # This implicitly depends on the other MediaWiki/PHP profiles
    file { "/usr/local/sbin/check-and-restart-${service}":
        ensure => $ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/mediawiki/php/php-check-and-restart.sh',
    }

    if member($all_nodes, $::fqdn) {
        $times = cron_splay($all_nodes, 'daily', "${service}-opcache-restarts")
        $hour = sprintf('%02d', $times['hour'])
        $minute = sprintf('%02d', $times['minute'])
        $systemd_timer_interval = sprintf('*-*-* %02d:%02d:00',$times['hour'], $times['minute'])

        # Using a systemd timer should ensure we can track if the job fails
        systemd::timer::job { "${service}_check_restart":
            description       => 'Cronjob to check the status of the opcache space on PHP7, and restart the service if needed',
            command           => "/usr/local/sbin/check-and-restart-${service} ${opcache_limit}",
            interval          => {'start' => 'OnCalendar', 'interval' => $systemd_timer_interval},
            user              => 'root',
            logfile_basedir   => '/var/log/mediawiki',
            syslog_identifier => "${service}_check_restart"
        }
    }

}
