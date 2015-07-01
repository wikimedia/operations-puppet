# == Class: tlsproxy::ocsp_updater
#
# This class defines a machine-global cronjob which keeps the OCSP Stapling
# files defined through tlsproxy::ocsp_stapler up to date at runtime.
#
# Note that everything about how we time/check this stuff today makes
# assumptions based on GlobalSign's OCSP validity time windows.  In the
# future, it would be better to find a way to make the cron/check -timing
# a bit more adaptive...
#

class tlsproxy::ocsp_updater {
    require ::sslcert

    file { '/usr/local/sbin/update-ocsp-all':
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/tlsproxy/update-ocsp-all',
    }

    file { '/etc/ocsp_updater':
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        ensure => 'directory',
    }

    cron { 'update-ocsp-all':
        command => "/usr/local/sbin/update-ocsp-all webproxy.${::site}.wmnet:8080",
        minute  => fqdn_rand(60, '1adf3dd699e51805'),
        hour    => '*',
        require => [
            File['/usr/local/sbin/update-ocsp-all'],
            File['/etc/ocsp_updater'],
            Service['nginx'],
        ],
    }

    # Generate icinga alert if OCSP files falling out of date due to errors
    #
    # Note this makes no provision for un-configured stapling at this time, so
    # it will generate warnings if you don't clean up old /var/cache/ocsp/
    # entries after removing a tlsproxy::ocsp_stapler cert from a server!
    #
    # The cron above attempts to get fresh data every hour, and a good fresh
    # fetch of data has a 12H lifetime with the windows we're seeing from
    # GlobalSign today.
    #
    # The crit/warn values of 29100 and 14700 correspond are "8h5m" and
    # "4h5m", so those are basically warning if 4 updates in a row failed
    # for a given cert, and critical if 8 updates in a row failed (at which
    # point we have 4h left to fix the situation before the validity window
    # expires).

    $check_args = '-c 29100 -w 14700 -d /var/cache/ocsp -g "*.ocsp"'
    nrpe::monitor_service { 'ocsp-freshness':
        description  => 'Freshness of OCSP Stapling files',
        nrpe_command => "/usr/lib/nagios/plugins/check-fresh-files-in-dir.py $check_args",
        require      => File['/usr/lib/nagios/plugins/check-fresh-files-in-dir.py'],
    }
}
