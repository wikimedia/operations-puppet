# SPDX-License-Identifier: Apache-2.0
class profile::dns::auth::update (
    Hash[Stdlib::Fqdn, Stdlib::IP::Address::Nosubnet] $authdns_servers         = lookup('authdns_servers'),
    Stdlib::HTTPSUrl                                  $gitrepo                 = lookup('profile::dns::auth::gitrepo'),
    Stdlib::Unixpath                                  $netbox_dns_snippets_dir = lookup('profile::dns::auth::update::netbox_dns_snippets_dir'),
    Stdlib::Fqdn                                      $netbox_exports_domain   = lookup('profile::dns::auth::update::netbox_exports_domain'),
    Hash[Stdlib::Fqdn, Stdlib::IP::Address::Nosubnet] $authdns_servers_ips     = lookup('profile::dns::auth::authdns_servers_ips'),
    Array[Wmflib::Sites]                              $datacenters             = lookup('datacenters'),
    Hash[String, Wmflib::Advertise_vip]               $advertise_vips          = lookup('profile::bird::advertise_vips', {'merge' => hash}),
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

    # safe.directory directive for the two below directories allows
    # authdns-local-update to be run without any permission issues.
    # See CR 888053 for more information.
    git::systemconfig { 'safe.directory-authdns-git':
        settings => {
            'safe' => {
                'directory' => '/srv/authdns/git',
            }
        },
        before   => Exec['authdns-local-update'],

    }
    git::systemconfig { 'safe.directory-netbox-snippets':
        settings => {
            'safe' => {
                'directory' => '/srv/git/netbox_dns_snippets',
            }
        },
        before   => Exec['authdns-local-update'],
    }

    $authdns_conf = '/etc/wikimedia-authdns.conf'

    $authdns_update_watch_keys = $datacenters.map |$dc| { "/pools/${dc}/dnsbox/authdns-update" }
    confd::file { $authdns_conf:
        ensure     => present,
        watch_keys => $authdns_update_watch_keys,
        content    => template('profile/dns/auth/wikimedia-authdns.conf.tpl.erb'),
        before     => Exec['authdns-local-update'],
    }

    $host_state_dir = '/var/lib/dnsbox'
    file { $host_state_dir:
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }
    # Manage service depooling via confd. This means iterating over the
    # services defined in advertise_vips and creating state files for them,
    # using their respective healthchecks.
    #
    # Since the basic wrapper is the same for all services, we use that and
    # template it, instead of duplicating the code.
    $advertise_vips.map |$vip_fqdn, $vip_params| {
        $service_type = $vip_params['service_type']
        $service_name = regsubst($service_type, '-', '_', 'G')

        $state_file = "${host_state_dir}/${service_name}.state"
        file { "/usr/local/bin/check_${service_name}_state":
            ensure  => present,
            mode    => '0755',
            content => template('profile/dns/auth/check_state.erb'),
            before  => Confd::File[$state_file],
        }

        $service_watch_keys = [ "/pools/${::site}/dnsbox/${service_type}/${::fqdn}" ]
        confd::file { $state_file:
            ensure     => present,
            watch_keys => $service_watch_keys,
            content    => template('profile/dns/auth/state.tpl.erb'),
            reload     => "/usr/local/bin/check_${service_name}_state",
            before     => Exec['authdns-local-update'],
        }
    }

    # confd now manages admin_state; see T369366
    $confd_admin_state_file = '/var/lib/gdnsd/admin_state'
    confd::file { $confd_admin_state_file:
        ensure     => present,
        watch_keys => ['/geodns'],
        content    => template('profile/dns/auth/admin_state.tpl.erb'),
        before     => Exec['authdns-local-update'],
    }

    ferm::service { 'authdns_update_ssh_rule':
        proto  => 'tcp',
        port   => '22',
        srange => "(${authdns_servers_ips.values().join(' ')})",
    }

    nrpe::plugin { 'check_authdns_update_run':
        content => template('profile/dns/auth/check_authdns_update_run.erb'),
    }

    nrpe::monitor_service { 'authdns_update_run':
        description    => 'check if authdns-update was run after a change was submitted to dns.git',
        nrpe_command   => '/usr/local/lib/nagios/plugins/check_authdns_update_run',
        check_interval => 5, # min
        retry_interval => 1, # min
        notes_url      => 'https://wikitech.wikimedia.org/wiki/DNS#authdns_update_run',
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
        timeout   => 600,   # 10 minutes
        notify    => Exec['authdns-local-update'],
    }

    exec { 'authdns-local-update':
        command => '/usr/local/sbin/authdns-local-update --skip-review --initial',
        user    => root,
        timeout => 60,
        # we don't want to run this if we have already run before and the files exist
        unless  => [ '/usr/bin/test -f /etc/gdnsd/config -a -f /etc/gdnsd/zones/netbox/eqiad.wmnet -a -f /etc/gdnsd/zones/wikipedia.org' ],
        # we prepare the config even before the package gets installed, leaving
        # no window where service would be started and answer with REFUSED
        before  => Package['gdnsd'],
    }
}
