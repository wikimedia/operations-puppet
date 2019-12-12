class profile::dns::auth::dotls(
    Hash[String, Hash[String, String]] $authdns_addrs = lookup('authdns_addrs'),
    String $cert_name = lookup('profile::dns::auth::dotls', {default_value => 'dotls-for-authdns'}),
) {
    # HAProxy needs the full chained cert *and* the private key in a single
    # file, which we're calling the "kchained" variant here:
    $chained_path = "/etc/acmecerts/${cert_name}/live/ec-prime256v1.chained.crt"
    $key_path = "/etc/acmecerts/${cert_name}/live/ec-prime256v1.key"
    $kchained_path = "/etc/acmecerts/${cert_name}/live/ec-prime256v1.kchained.crt"

    acme_chief::cert { $cert_name:
        puppet_rsc => Exec['make-haproxy-crt'],
    }

    exec { 'make-haproxy-crt':
        command     => "/bin/cat ${key_path} ${chained_path} >${kchained_path}",
        umask       => '027',
        refreshonly => true,
        notify      => Service['haproxy'],
    }

    $listen_addrs = $authdns_addrs.map |$aspec| { $aspec[1]['address'] }

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
        ensure => 'running',
    }

    class { 'prometheus::haproxy_exporter':
        endpoint => 'http://127.0.0.1:8404/?stats;csv',
    }

    # XXX needs ferm rules for port 853
    # XXX needs monitoring, probably NRPE+kdig for now?
    package { 'knot-dnsutils':
        ensure => present,
    }
}
