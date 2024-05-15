# SPDX-License-Identifier: Apache-2.0
# The default load balancer for Pontoon.

# Provides the required integration with puppet.git for pontoon::lb class.

class profile::pontoon::lb (
  $public_domain = lookup('public_domain'),
) {
    $role_services = wmflib::service::fetch().filter |$name, $config| {
        ('role' in $config and pontoon::hosts_for_role($config['role']))
    }

    class { 'pontoon::lb':
        services_config => $role_services,
        public_domain   => $public_domain,
    }

    $ports = unique($role_services.map |$name, $svc| { $svc['port'] })

    $ports.sort.each |$p| {
        firewall::service { "pontoon-lb-${p}":
            proto   => 'tcp',
            notrack => true,
            port    => $p,
        }
    }

    # LB can act as a Cloud VPS backend to proxy public services
    firewall::service { 'pontoon-webproxy-backend':
        proto => 'tcp',
        port  => 80,
    }

    # Additional DNS listener for SD to work within containers.
    # '127.0.0.1' is normally used in /etc/resolv.conf by Pontoon SD, which
    # doesn't work inside containers because of a different network namespace.
    file { '/etc/dnsmasq.d/pontoon-lb.conf':
        content => "listen-address=${facts['ipaddress']}",
        notify  => Exec['dnsmasq-restart'],
    }

    ['udp', 'tcp'].each |$proto| {
        firewall::service { "pontoon-lb-dns-${proto}":
            proto   => $proto,
            notrack => true,
            port    => 53,
        }
    }
}
