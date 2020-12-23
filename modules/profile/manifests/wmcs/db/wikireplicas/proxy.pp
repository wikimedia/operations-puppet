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
    debian::codename::require::min('buster')

    package { 'haproxy':
        ensure => present,
    }

    file { '/etc/haproxy/conf.d':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/haproxy/haproxy.cfg':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        # TODO: This is due for a refactor so temporarily reusing toolforge file.
        content => template('profile/toolforge/k8s/haproxy/haproxy.cfg.erb'),
        notify  => Service['haproxy'],
    }

    file { '/etc/haproxy/conf.d/upstream-proxies.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/wmcs/db/wikireplicas/proxy/upstream-proxies.cfg.erb'),
        notify  => Service['haproxy'],
    }

    # this file is loaded as environmentfile in the .service file shipped by
    # the debian package in Buster
    file { '/etc/default/haproxy':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => "EXTRAOPTS='-f /etc/haproxy/conf.d/'\n",
        notify  => Service['haproxy'],
    }

    # To get logging working, rsyslog needs to know what to do with it
    logrotate::conf { 'haproxy':
        ensure => present,
        source => 'puppet:///modules/profile/toolforge/k8s/haproxy/haproxy.logrotate',
    }

    rsyslog::conf { 'haproxy':
          source   => 'puppet:///modules/profile/toolforge/k8s/haproxy/haproxy.rsyslog',
          priority => 49,
    }

    service { 'haproxy':
        ensure    => 'running',
        subscribe => [
                  File['/etc/haproxy/haproxy.cfg'],
                  File['/etc/default/haproxy'],
        ],
    }

    class { 'prometheus::haproxy_exporter': }
}
