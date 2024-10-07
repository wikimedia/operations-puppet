# SPDX-License-Identifier: Apache-2.0
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
    String              $auth_pass,
    Array[Stdlib::IP::Address] $vips,
    Enum['BACKUP', 'MASTER']   $default_state = 'BACKUP',
    String              $interface            = $::facts['networking']['primary'],
    Integer             $priority             = fqdn_rand(100),
    Integer             $virtual_router_id    = 51,
    String              $config               = '',
) {
    if debian::codename::eq('bullseye') {
        # default keepalived in bullseye seems broken, see
        # https://bugs.debian.org/1008222
        apt::package_from_bpo { 'keepalived':
            distro => 'bullseye',
        }
    }

    package { 'keepalived':
        ensure => present,
    }

    # support for arbitrary config file
    if $config == '' {
        $content = template('keepalived/keepalived.conf.erb')
    } else {
        $content = $config
    }

    $conf_file = '/etc/keepalived/keepalived.conf'
    file { $conf_file :
        ensure    => present,
        mode      => '0444',
        owner     => 'root',
        group     => 'root',
        content   => $content,
        show_diff => false,
        require   => Package['keepalived'],
    }

    service { 'keepalived':
        ensure    => running,
        subscribe => [
            Package['keepalived'],
            File[$conf_file],
        ],
    }
}
