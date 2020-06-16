# == Class: keepalived
#
# === Parameters
#
# [*auth_pass*]
#   Authentication password to use between peers
# [*default_state*]
#   Default state of the host (MASTER|BACKUP)
# [*interface*]
#   Network interface to run the virtual address on
# [*peers*]
#   List of peers
# [*priority*]
#   VRRP priority of this host
# [*virtual_router_id*]
#   VRRP virtual router id this host belongs to
# [*vips*]
#   List of virtual IP address managed by keepalived (<ipaddress/cidr)
#

class keepalived(
    Array[Stdlib::Fqdn] $peers,
    Integer             $priority,
    Integer             $virtual_router_id,
    String              $auth_pass,
    String              $default_state,
    String              $interface,
    Array[Stdlib::IP::Address] $vips,
) {

    package { 'keepalived':
        ensure => present,
    }

    file { '/etc/keepalived/keepalived.conf':
        ensure    => present,
        mode      => '0444',
        owner     => 'root',
        group     => 'root',
        content   => template('keepalived/keepalived.conf.erb'),
        show_diff => false,
        require   => Package['keepalived'],
        notify    => Exec['restart-keepalived'],
    }

    exec { 'restart-keepalived':
        command     => '/bin/systemctl restart keepalived',
        refreshonly => true,
    }
}
