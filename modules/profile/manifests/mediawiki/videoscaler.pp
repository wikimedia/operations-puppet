class profile::mediawiki::videoscaler()
{
    include ::mediawiki::users

    package { [
        'ffmpeg',
    ]:
        ensure => present,
    }

    # Change the apache2.conf Timeout setting
    augeas { 'apache timeout':
        incl    => '/etc/apache2/apache2.conf',
        lens    => 'Httpd.lns',
        changes => [
            'set /files/etc/apache2/apache2.conf/directive[self::directive="Timeout"]/arg 86400',
        ],
        notify  => Service['apache2'],
    }

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
}
