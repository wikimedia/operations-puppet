# == Class authdns
# A class to implement Wikimedia's authoritative DNS system
#
class authdns(
    $soa_name = $::fqdn,
    $nameservers = [ $::fqdn ],
    $ipaddress = undef,
    $ipaddress6 = undef,
    $gitrepo = undef,
    $managed_iface = 'eth0',
) {
    Class['authdns::scripts'] -> Class['authdns']
    Class['::geoip'] -> Class['authdns']

    include authdns::scripts
    class { '::geoip':
        data_provider => 'package',
    }

    package { 'gdnsd':
        ensure => installed,
    }

    service { 'gdnsd':
        ensure     => running,
        hasrestart => true,
        hasstatus  => true,
        require    => Package['gdnsd'],
    }

    # do the initial clone via puppet; subsequent ones happen manually
    git::clone{ '/etc/gdnsd':
        directory => '/etc/gdnsd',
        origin    => $gitrepo,
        branch    => 'master',
        before    => Package['gdnsd'],
        notify    => Exec['authdns-local-update'],
    }

    file { '/etc/gdnsd/config-head':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('authdns/config-head.erb'),
        # this feels weird but git::clone is the one to create the dir
        require => Git::Clone['/etc/gdnsd'],
    }

    file { '/etc/wikimedia-authdns.conf':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('authdns/wikimedia-authdns.conf.erb'),
    }

    exec { 'authdns-local-update':
        command     => '/usr/local/sbin/authdns-local-update',
        user        => root,
        refreshonly => true,
        timeout     => 60,
        require     => [
                File['/etc/wikimedia-authdns.conf'],
                File['/etc/gdnsd/config-head'],
            ],
        # we prepare the config even before the package gets installed, leaving
        # no window where service would be started and answer with REFUSED
        before      => Package['gdnsd'],
    }

    if $ipaddress and $managed_iface {
        interface_ip { 'authdns_ipv4':
            interface => $managed_iface,
            address   => $ipaddress,
            before    => Package['gdnsd'],
        }
    }
    if $ipaddress6 and $managed_iface {
        interface_ip { 'authdns_ipv6':
            interface => $managed_iface,
            address   => $ipaddress6,
            prefixlen => 64,
            before    => Package['gdnsd'],
        }
    }
}
