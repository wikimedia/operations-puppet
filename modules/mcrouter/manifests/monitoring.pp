# == Class: mcrouter::monitoring
#
# Provisions Icinga alerts for mcrouter.
#
class mcrouter::monitoring {

    require_package('python3-tz')
    require_package('python3-openssl')
    require_package('python3-nagiosplugin')

    file { '/usr/lib/nagios/plugins/nrpe_check_client_cert':
        ensure  => present,
        source  => 'puppet:///modules/mcrouter/nrpe_check_client_cert/check_client_cert.py',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => Service['mcrouter'],
    }

    sudo::user { 'nagios_check_mcrouter_client':
        user       => 'nagios',
        privileges => ['ALL = NOPASSWD: /usr/lib/nagios/plugins/nrpe_check_client_cert'],
    }

    nrpe::monitor_service{ 'mcrouter_cert_expiration':
        description    => 'mcrouter certs expiration check',
        # forcing --no-server-check as check doesnt send client cert
        # for validation and would fail against mcrouter
        nrpe_command   => 'sudo -u mcrouter /usr/lib/nagios/plugins/nrpe_check_client_cert --no-server-check',
        require        => [
          File['/usr/lib/nagios/plugins/nrpe_check_client_cert'],
          Sudo::User['nagios_check_mcrouter_client'],
        ],
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Mcrouter',
        check_interval => 60,
        retry_interval => 10,
    }

    nrpe::monitor_service { 'mcrouter':
        description  => 'mcrouter process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -u mcrouter -C mcrouter',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Mcrouter',
    }
}
