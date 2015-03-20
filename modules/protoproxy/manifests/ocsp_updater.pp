# == Class: protoproxy::ocsp_updater
#
# This class defines a machine-global cronjob which updates
# any existing OCSP files in /var/cache/ocsp once every two
# hours, randomly splayed per-machine.
#
# It is intended to be used as "include protoproxy::ocsp_updater"
# any time an ocsp file is defined for creation on a given machine.
# See protoproxy::localssl for example.
#
# Note that everything about how we time/check this stuff today makes
# assumptions based on GlobalSign's OCSP validity time windows.  In the
# future, it would be better to find a way to make the cron/check -timing
# a bit more adaptive...
#

class protoproxy::ocsp_updater {
    require ::sslcert

    file { '/usr/local/sbin/update-ocsp-all.sh':
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/protoproxy/update-ocsp-all.sh',
    }

    # This is "0" or "1" randomly by-host, used below with Linux crontab
    # syntax to get every-two-hours timing with hosts splayed into even/odd hours
    $fqr01 = fqdn_rand(2, '97e54956f8c8e861')

    cron { 'update-ocsp-all':
        command => "/usr/local/sbin/update-ocsp-all.sh webproxy.${::site}.wmnet:8080",
        minute  => fqdn_rand(60, '1adf3dd699e51805'),
        hour    => "${fqr01}-23/2",
        require => [
            File['/usr/local/sbin/update-ocsp-all.sh'],
            Service['nginx'],
        ],
    }

    # Generate icinga alert if OCSP files falling out of date due to errors
    #
    # The cron above attempts to get fresh data every 2 hours, and a good
    # fresh fetch of data has a 12H lifetime with the windows we're seeing
    # from GlobalSign today.
    #
    # The crit/warn values of 29100 and 14700 correspond are "8h5m" and
    # "4h5m", so those are basically warning if two updates in a row failed
    # for a given cert, and critical if 4 updates in a row fail (at which
    # point we have 4h left to fix the situation before the validity window
    # expires).

    $check_args = '-c 29100 -w 14700 -d /var/cache/ocsp -g "*.ocsp"'
    nrpe::monitor_service { 'ocsp-freshness':
        description  => 'Freshness of OCSP Stapling files',
        nrpe_command => "/usr/lib/nagios/plugins/check-fresh-files-in-dir.py $check_args",
        require => File['/usr/lib/nagios/plugins/check-fresh-files-in-dir.py'],
    }
}
