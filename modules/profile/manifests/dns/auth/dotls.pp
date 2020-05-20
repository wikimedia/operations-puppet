class profile::dns::auth::dotls(
    Hash[String, Hash[String, String]] $authdns_addrs = lookup('authdns_addrs'),
    String $cert_name = lookup('profile::dns::auth::dotls', {default_value => 'dotls-for-authdns'}),
) {
    include ::profile::prometheus::haproxy_exporter

    # HAProxy needs the full chained cert *and* the private key in a single
    # file, which we're calling the "kchained" variant here:
    $chained_path = "/etc/acmecerts/${cert_name}/live/ec-prime256v1.chained.crt"
    $key_path = "/etc/acmecerts/${cert_name}/live/ec-prime256v1.key"
    $kchained_path = "/etc/acmecerts/${cert_name}/live/ec-prime256v1.kchained.crt"

    # Haproxy also wants the OCSP file to be the full path of the cert (kchained above) + ".ocsp"
    $ocsp_path = "/etc/acmecerts/${cert_name}/live/ec-prime256v1.ocsp"
    $ocsp_full_path = "${kchained_path}.ocsp"

    acme_chief::cert { $cert_name:
        puppet_rsc => Exec['make-haproxy-crt'],
    }

    exec { 'make-haproxy-crt':
        command     => "/bin/cat ${key_path} ${chained_path} >${kchained_path}; /bin/cp ${ocsp_path} ${ocsp_full_path}",
        umask       => '027',
        refreshonly => true,
        notify      => Service['haproxy'],
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
        ensure => present,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/profile/dns/auth/dot-needs-auth.conf',
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

    file { '/usr/local/lib/nagios/plugins/check_dotls':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/dns/auth/check_dotls',
    }

    nrpe::monitor_service { 'check_dotls':
        description  => 'AuthDNS-over-TLS Works',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_dotls',
        require      => File['/usr/local/lib/nagios/plugins/check_dotls'],
        notes_url    => 'https://wikitech.wikimedia.org/wiki/DNS',
    }
}
