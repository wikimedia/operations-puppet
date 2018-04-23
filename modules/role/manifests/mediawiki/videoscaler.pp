# filtertags: labs-project-deployment-prep
class role::mediawiki::videoscaler {
    system::role { 'mediawiki::videoscaler': }

    include ::role::mediawiki::common
    include ::mediawiki::multimedia

    file { '/etc/wikimedia-scaler':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    # monitor orphaned HHVM threads/requests that are no longer in apache
    # see https://phabricator.wikimedia.org/T153488
    file { '/usr/local/lib/nagios/plugins/check_leaked_hhvm_threads':
        ensure => present,
        source => 'puppet:///modules/role/mediawiki/check_leaked_hhvm_threads.py',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    # For some versions of httpd (like 2.4.7), BusyWorkers are set to zero when
    # a graceful restart happens, even if outstanding requests are not dropped
    # or marked as Graceful closing.
    # This means that daily tasks like logrotate cause false positives.
    # A quick workaround is to use a high enough number of retries monitoring check,
    # to give httpd time to restore its busy workers.
    # This is not an ideal solution but a constant rate of false positives
    # decreases the perceived importance of the alarm over time.
    nrpe::monitor_service { 'check_leaked_hhvm_threads':
        description    => 'Check HHVM threads for leakage',
        nrpe_command   => '/usr/local/lib/nagios/plugins/check_leaked_hhvm_threads',
        check_interval => 5,
        retry_interval => 5,
        retries        => 10,
        require        => File['/usr/local/lib/nagios/plugins/check_leaked_hhvm_threads'],
    }

    # Profiles
    include ::profile::prometheus::apache_exporter
    include ::profile::prometheus::hhvm_exporter
    include ::profile::mediawiki::jobrunner
    include ::base::firewall

    # Change the apache2.conf Timeout setting
    augeas { 'apache timeout':
        incl    => '/etc/apache2/apache2.conf',
        lens    => 'Httpd.lns',
        changes => [
            'set /files/etc/apache2/apache2.conf/directive[self::directive="Timeout"]/arg 86400',
        ],
        notify  => Service['apache2'],
    }

    # The apache2 systemd unit in stretch enables PrivateTmp by default
    # This makes "systemctl reload apache" fail with error code 226/EXIT_NAMESPACE
    # (which is a failure to setup a mount namespace). This is specific to our
    # mediawiki setup:
    # Normally, with PrivateTmp enabled, /tmp would appear as
    # /tmp/systemd-private-$ID-apache2.service-$RANDOM and /var/tmp would appear as
    # /var/tmp/systemd-private-$ID-apache2.service-$RANDOM. That works fine for
    # /var/tmp, but fails for /tmp (so the reload only exposes the issue)
    #
    # Disable PrivateTmp on stretch, it prevents Apache reloads (as e.g. triggered by
    # logrorate) for current video scalers and we can revisit this when phasing out HHVM.
    #
    # To disable, ship a custom systemd override when running on stretch; we have
    # a cleaner mechanism to pass an override via systemd::unit, but that would require
    # extensive changes and since the mediawiki classes are up for major refactoring
    # soon, add this via simple file references for now
    if os_version('debian >= stretch') {
        file { '/etc/systemd/system/apache2.service.d':
            ensure => directory,
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
        }

        file { '/etc/systemd/system/apache2.service.d/override.conf':
            ensure  => present,
            mode    => '0755',
            owner   => 'root',
            group   => 'root',
            content => "[Service]\nPrivateTmp=false\n",
            notify  => Exec['mediawiki-videoscaler-apache-systemctl-override-daemon-reload'],
        }

        exec { 'mediawiki-videoscaler-apache-systemctl-override-daemon-reload':
            command     => '/bin/systemctl daemon-reload',
            refreshonly => true,
        }
    }
}
