# SPDX-License-Identifier: Apache-2.0
class profile::dns::auth::update (
    Hash[Stdlib::Fqdn, Stdlib::IP::Address::Nosubnet] $authdns_servers         = lookup('authdns_servers'),
    Stdlib::HTTPSUrl                                  $gitrepo                 = lookup('profile::dns::auth::gitrepo'),
    Stdlib::Unixpath                                  $netbox_dns_snippets_dir = lookup('profile::dns::auth::update::netbox_dns_snippets_dir'),
    Stdlib::Unixpath                                  $netbox_dns_records_dir  = lookup('profile::dns::auth::update::netbox_dns_records_dir'),
    Stdlib::Fqdn                                      $netbox_exports_domain   = lookup('profile::dns::auth::update::netbox_exports_domain'),
    Hash[Stdlib::Fqdn, Stdlib::IP::Address::Nosubnet] $authdns_servers_ips     = lookup('profile::dns::auth::authdns_servers_ips'),
    Array[Wmflib::Sites]                              $datacenters             = lookup('datacenters'),
    Hash[String, Wmflib::Advertise_vip]               $advertise_vips          = lookup('profile::bird::advertise_vips', {'merge' => hash}),
    Stdlib::Host                                      $tcpircbot_host          = lookup('tcpircbot_host'),
    Stdlib::Port                                      $tcpircbot_port          = lookup('tcpircbot_port'),
) {
    require ::profile::dns::auth::update::account
    require ::profile::dns::auth::update::scripts

    $workingdir = '/srv/authdns/git'
    # Here and elsewhere, 'dns_snippets' is the existing/legacy generated records,
    # and 'dns_records' is for the files created by the new cookbook that will
    # eventually replace it
    $netbox_dns_snippets_repo = "https://${netbox_exports_domain}/dns.git"
    $netbox_dns_records_repo = "https://${netbox_exports_domain}/netbox-dns"
    $netbox_dns_user = 'netboxdns'

    user { $netbox_dns_user:
        ensure  => present,
        comment => 'User for the Netbox generated DNS zonefile snippets',
        system  => true,
        shell   => '/bin/bash',
    }

    # Creates /srv/git/ which both our snippet/records repos are cloned to
    file { dirname($netbox_dns_records_dir):
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
                'directory' => $workingdir,
            }
        },
        before   => Exec['authdns-local-update'],

    }
    git::systemconfig { 'safe.directory-netbox-snippets':
        settings => {
            'safe' => {
                'directory' => $netbox_dns_snippets_dir,
            }
        },
        before   => Exec['authdns-local-update'],
    }
    git::systemconfig { 'safe.directory-netbox-records':
        settings => {
            'safe' => {
                'directory' => $netbox_dns_records_dir,
            }
        },
        before   => Exec['authdns-local-update'],
    }

    # systemd timer to run git gc once a month. This results in signficant
    # performance improvements for authdns-update and is documented in T393602.
    systemd::timer::job { 'gc-authdns-git-repo':
        ensure      => present,
        description => 'Run git maintenance run to optimize authdns Git repository',
        user        => 'authdns',
        command     => "/usr/bin/git -C ${workingdir} maintenance run",
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => 'Mon *-*-01..07 14:00:00',
        },
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

        $service_watch_keys = [ "/pools/${::site}/dnsbox/${service_type}/${facts['networking']['fqdn']}" ]
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

    confd::file { '/var/lib/prometheus/node.d/geodns-conftool-state.prom':
        ensure     => present,
        prefix     => '/geodns',
        watch_keys => ['/'],
        content    => template('profile/discovery/geodns-prometheus.prom.erb'),
        mode       => '0444',
    }

    firewall::service { 'authdns_update_ssh_rule':
        proto  => 'tcp',
        port   => 22,
        srange => $authdns_servers_ips.values(),
    }

    nrpe::plugin { 'check_authdns_update_run':
        content => template('profile/dns/auth/check_authdns_update_run.erb'),
    }

    nrpe::monitor_service { 'authdns_update_run':
        description        => 'check if authdns-update was run after a change was merged to operations/dns.git',
        nrpe_command       => '/usr/local/lib/nagios/plugins/check_authdns_update_run',
        check_interval     => 5, # min
        retry_interval     => 5, # min
        notes_url          => 'https://wikitech.wikimedia.org/wiki/DNS#authdns_update_run',
        migration_task     => 'T384425',
        enable_nrpe2nodexp => true,
        sudo_user          => 'authdns',
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
        timeout   => 1200,   # (seconds) Initial clone can take a long time
        notify    => Exec['authdns-local-update'],
    }

    # Clone the new-format Netbox exported DNS snippet files to the other repo dir
    git::clone { $netbox_dns_records_dir:
        directory => $netbox_dns_records_dir,
        origin    => $netbox_dns_records_repo,
        branch    => 'master',
        owner     => $netbox_dns_user,
        group     => $netbox_dns_user,
        timeout   => 600,   # 10 minutes
        # TODO: notify    => Exec['authdns-local-update'],
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
