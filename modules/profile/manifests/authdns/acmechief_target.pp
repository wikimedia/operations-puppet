class profile::authdns::acmechief_target(
    $acmechief_hosts=hiera('profile::authdns::acmechief_target::acmechief_hosts'),
) {
    user { 'acme-chief':
        ensure => present,
        system => true,
        home   => '/nonexistent',
        shell  => '/bin/bash',
    }

    ssh::userkey { 'acme-chief':
        content => secret('keyholder/authdns_acmechief.pub'),
    }

    sudo::user { 'acme-chief':
        privileges => [
            'ALL = (gdnsd) NOPASSWD: /usr/bin/gdnsdctl -- acme-dns-01 *',
        ],
    }

    $hosts = join($acmechief_hosts, ' ')
    ferm::service { 'acmechief_dns_ssh':
        proto  => 'tcp',
        port   => '22',
        srange => "(@resolve((${hosts})) @resolve((${hosts}), AAAA))",
    }
}
