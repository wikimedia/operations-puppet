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
}
