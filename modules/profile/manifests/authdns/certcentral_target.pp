class profile::authdns::certcentral_target(
    $certcentral_hosts=hiera('profile::authdns::certcentral_target::certcentral_hosts'),
) {
    user { 'certcentral':
        ensure => absent,
        system => true,
        home   => '/nonexistent',
        shell  => '/bin/bash',
    }

    ssh::userkey { 'certcentral':
        ensure  => absent,
        content => secret('keyholder/authdns_certcentral.pub'),
    }

    sudo::user { 'certcentral':
        ensure     => absent,
        privileges => [
            'ALL = (gdnsd) NOPASSWD: /usr/bin/gdnsdctl -- acme-dns-01 *',
        ],
    }

    $hosts = join($certcentral_hosts, ' ')
    ferm::service { 'certcentral_dns_ssh':
        ensure => absent,
        proto  => 'tcp',
        port   => '22',
        srange => "(@resolve((${hosts})) @resolve((${hosts}), AAAA))",
    }
}
