# SPDX-License-Identifier: Apache-2.0
class profile::dns::auth::dotls(
    Hash[String, Hash[String, Any]] $authdns_addrs = lookup('authdns_addrs'),
    String $cert_name = lookup('profile::dns::auth::dotls', {default_value => 'dotls-for-authdns'}),
) {
    include ::profile::prometheus::haproxy_exporter

    # HAProxy needs the full chained cert *and* the private key in a single file
    $kchained_path = "/etc/acmecerts/${cert_name}/live/ec-prime256v1.alt.chained.crt.key"

    acme_chief::cert { $cert_name:
        puppet_rsc => Service['haproxy'],
    }

    file { '/etc/haproxy/haproxy.cfg':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('profile/dns/auth/haproxy.cfg.erb'),
        notify  => Service['haproxy'],
        require => Package['haproxy'],
    }

    package { 'haproxy':
        ensure => present,
    }

    service { 'haproxy':
        ensure  => 'running',
        restart => 'systemctl reload haproxy.service',
        require => Service['gdnsd'],
    }

    # This is the systemd-level glue to ensure haproxy cannot be
    # running unless gdnsd is already running

    $sysd_dir = '/etc/systemd/system/haproxy.service.d'
    $sysd_glue = "${sysd_dir}/dot-needs-auth.conf"
    file { $sysd_dir:
        ensure => directory,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }
    file { $sysd_glue:
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/profile/dns/auth/dot-needs-auth.conf',
        require => Service['gdnsd'],
    }
    exec { 'systemd reload for dot-needs-auth glue':
        refreshonly => true,
        command     => '/bin/systemctl daemon-reload',
        subscribe   => File[$sysd_glue],
        before      => Service['haproxy'],
        require     => Service['gdnsd'],
    }

    $service_listeners = $authdns_addrs.map |$aspec| { $aspec[1]['address'] }
    ferm::service { 'tcp_dotls_auth':
        proto   => 'tcp',
        notrack => true,
        prio    => '06',
        port    => '853',
        drange  => "(${service_listeners.join(' ')})",
    }

    # Provides "kdig" command used by check_dotls below
    package { 'knot-dnsutils':
        ensure => present,
    }

    nrpe::plugin { 'check_dotls':
        source => 'puppet:///modules/profile/dns/auth/check_dotls',
    }

    nrpe::monitor_service { 'check_dotls':
        description  => 'AuthDNS-over-TLS Works',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_dotls',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/DNS',
    }
}
