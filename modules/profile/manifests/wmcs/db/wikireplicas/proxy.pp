class profile::wmcs::db::wikireplicas::proxy (
    Hash[String,Stdlib::IP::Address::V4] $haproxy_vips = lookup('profile::wmcs::db::wikireplicas::vips', {default_value => {'s1' => '8.8.8.8'}}),
    Hash[String,Stdlib::Port] $section_ports = lookup('profile::mariadb::section_ports'),
    Hash[String,Stdlib::Fqdn] $section_backends = lookup('profile::wmcs::db::wikireplicas::section_backends', {default_value => {'s1' => 'db1.local'}}),
) {
    $haproxy_vips.each |$sect, $ip| {
        interface::alias { "${sect}-vip":
            ipv4 => $ip,
        }
    }
    class { 'haproxy::cloud::base': }

    file { '/etc/haproxy/conf.d/upstream-proxies.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/wmcs/db/wikireplicas/proxy/upstream-proxies.cfg.erb'),
        notify  => Service['haproxy'],
    }
    class { 'prometheus::haproxy_exporter': }
}
