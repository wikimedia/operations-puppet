# SPDX-License-Identifier: Apache-2.0
class profile::dns::auth::update (
    Hash[Stdlib::Fqdn, Stdlib::IP::Address::Nosubnet] $authdns_servers = lookup('authdns_servers'),
    Stdlib::HTTPSUrl $gitrepo = lookup('profile::dns::auth::gitrepo'),
    Stdlib::Unixpath $netbox_dns_snippets_dir = lookup('profile::dns::auth::update::netbox_dns_snippets_dir'),
    Stdlib::Fqdn $netbox_exports_domain = lookup('profile::dns::auth::update::netbox_exports_domain'),
) {
    require ::profile::dns::auth::update::account
    require ::profile::dns::auth::update::scripts

    $workingdir = '/srv/authdns/git'
    $netbox_dns_snippets_repo = "https://${netbox_exports_domain}/dns.git"
    $netbox_dns_user = 'netboxdns'

    user { $netbox_dns_user:
        ensure  => present,
        comment => 'User for the Netbox generated DNS zonefile snippets',
        system  => true,
        shell   => '/bin/bash',
    }

    file { dirname($netbox_dns_snippets_dir):
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        before => Exec['authdns-local-update'],
    }

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
    $authdns_servers.each |$s_name,$s_ip| {
        host { $s_name:
            ip           => $s_ip,
            host_aliases => split($s_name, '[.]')[0],
        }
    }

    # Hardcode the same IPv4 addrs as above in the inter-authdns ferm rules for
    # ssh access as well
    ferm::service { 'authdns_update_ssh':
        proto  => 'tcp',
        port   => '22',
        srange => "(${authdns_servers.values().join(' ')})",
    }

    # The clones and exec below are only for the initial puppetization of a
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

    # Clone the Netbox exported DNS snippet zonefiles with automatically generated
    # DNS records from Netbox data.
    git::clone { $netbox_dns_snippets_dir:
        directory => $netbox_dns_snippets_dir,
        origin    => $netbox_dns_snippets_repo,
        branch    => 'master',
        owner     => $netbox_dns_user,
        group     => $netbox_dns_user,
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
