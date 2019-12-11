class profile::dns::auth::update (
    Hash[Stdlib::Fqdn, Stdlib::IP::Address::Nosubnet] $authdns_servers = lookup('authdns_servers'),
    Stdlib::HTTPSUrl $gitrepo = lookup('profile::dns::auth::gitrepo'),
) {
    require ::profile::dns::auth::update::account
    require ::profile::dns::auth::update::scripts

    $workingdir = '/srv/authdns/git'

    file { '/etc/wikimedia-authdns.conf':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('profile/dns/auth/wikimedia-authdns.conf.erb'),
        before  => Exec['authdns-local-update'],
    }

    # Create explicit /etc/hosts entries for all authdns IPv4 to reach each
    # other by-hostname without working recdns
    create_resources('host', $authdns_servers.reduce({}) |$data,$kv| {
        $data + { $kv[0] => {
            ip => $kv[1],
            host_aliases => split($kv[0], '[.]')[0]
        }}
    })

    # Hardcode the same IPv4 addrs as above in the inter-authdns ferm rules for
    # ssh access as well
    ferm::service { 'authdns_update_ssh':
        proto  => 'tcp',
        port   => '22',
        srange => "(${authdns_servers.values().join(' ')})",
    }

    # The clone and exec below are only for the initial puppetization of a
    # fresh host, ensuring that the data and configuration are fully present
    # *before* the daemon is ever started for the first time (which can only be
    # gauranteed by doing it before the package is even installed).  Most other
    # daemon configuration needs a "before => Exec['authdns-local-update']" to
    # ensure it is also a part of this process.

    git::clone { $workingdir:
        directory => $workingdir,
        origin    => $gitrepo,
        branch    => 'master',
        owner     => 'authdns',
        group     => 'authdns',
        notify    => Exec['authdns-local-update'],
    }

    exec { 'authdns-local-update':
        command     => '/usr/local/sbin/authdns-local-update --skip-review --initial',
        user        => root,
        refreshonly => true,
        timeout     => 60,
        # we prepare the config even before the package gets installed, leaving
        # no window where service would be started and answer with REFUSED
        before      => Package['gdnsd'],
    }
}
