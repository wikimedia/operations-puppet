class profile::wmcs::paws::k8s::haproxy (
    Array[Stdlib::Fqdn] $ingress_nodes          = lookup('profile::wmcs::paws::ingress_nodes',         {default_value => ['localhost']}),
    Stdlib::Port        $ingress_backend_port   = lookup('profile::wmcs::paws::ingress_backend_port',  {default_value => 30000}),
    Stdlib::Port        $ingress_bind_tls_port  = lookup('profile::wmcs::paws::ingress_bind_tls_port', {default_value => 443}),
    Stdlib::Port        $ingress_bind_http_port = lookup('profile::wmcs::paws::ingress_bind_http_port',{default_value => 80}),
    Array[Stdlib::Fqdn] $control_nodes          = lookup('profile::wmcs::paws::control_nodes',         {default_value => ['localhost']}),
    Stdlib::Port        $api_port               = lookup('profile::wmcs::paws::apiserver_port',        {default_value => 6443}),
    Array[Stdlib::Fqdn] $keepalived_vips        = lookup('profile::wmcs::paws::keepalived::vips',      {default_value => ['localhost']}),
    Array[Stdlib::Fqdn] $keepalived_peers       = lookup('profile::wmcs::paws::keepalived::peers',     {default_value => ['localhost']}),
    String              $keepalived_password    = lookup('profile::wmcs::paws::keepalived::password',  {default_value => 'notarealpassword'}),
) {
    requires_os('debian >= buster')

    $cert_name = 'paws'
    acme_chief::cert { $cert_name:
        puppet_rsc => Service['haproxy'],
    }
    $cert_file = "/etc/acmecerts/${cert_name}/live/ec-prime256v1.chained.crt.key"

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
        content => template('profile/wmcs/paws/k8s/haproxy/haproxy.cfg.erb'),
        notify  => Service['haproxy'],
    }

    file { '/etc/haproxy/conf.d/k8s-api-servers.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/wmcs/paws/k8s/haproxy/k8s-api-servers.cfg.erb'),
        notify  => Service['haproxy'],
    }

    file { '/etc/haproxy/conf.d/k8s-ingress.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/wmcs/paws/k8s/haproxy/k8s-ingress.cfg.erb'),
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
        source => 'puppet:///modules/profile/wmcs/paws/k8s/haproxy/haproxy.logrotate',
    }

    rsyslog::conf { 'haproxy':
          source   => 'puppet:///modules/profile/wmcs/paws/k8s/haproxy/haproxy.rsyslog',
          priority => 49,
    }

    service { 'haproxy':
        ensure    => 'running',
        subscribe => [
                  File['/etc/haproxy/haproxy.cfg'],
                  File['/etc/haproxy/conf.d/k8s-api-servers.cfg'],
                  File['/etc/haproxy/conf.d/k8s-ingress.cfg'],
                  File['/etc/default/haproxy'],
        ],
    }

    class { 'prometheus::haproxy_exporter': }

    class { 'keepalived':
        auth_pass => $keepalived_password,
        peers     => delete($keepalived_peers, $::fqdn),
        vips      => $keepalived_vips.map |$host| { ipresolve($host, 4) }
    }
}
