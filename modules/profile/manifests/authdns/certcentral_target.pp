class profile::authdns::certcentral_target(
    $certcentral_hosts=hiera('profile::authdns::certcentral_target::certcentral_hosts'),
) {
    user { 'certcentral':
        ensure => present,
        system => true,
        home   => '/nonexistent',
        shell  => '/bin/bash',
    }

    ssh::userkey { 'certcentral':
        content => secret('ssh/authdns-certcentral.pub'),
    }

    sudo::user { 'certcentral':
        privileges => [
            'ALL = (gdnsd) NOPASSWD: /usr/bin/gdnsdctl -- acme-dns-01 *',
        ],
    }

    $hosts = join($certcentral_hosts, ' ')
    ferm::service { 'certcentral_dns_ssh':
        proto  => 'tcp',
        port   => '22',
        srange => "(@resolve((${hosts})) @resolve((${hosts}), AAAA))",
    }
}
