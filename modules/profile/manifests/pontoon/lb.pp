# The default load balancer for Pontoon.

# Provides the required integration with puppet.git for pontoon::lb class.

class profile::pontoon::lb {
    require_package('hatop')

    $role_services = wmflib::service::fetch().filter |$name, $config| {
        ('role' in $config and pontoon::hosts_for_role($config['role']))
    }

    class { 'pontoon::lb':
        services_config => $role_services,
    }

    $ports = unique($role_services.map |$name, $svc| { $svc['port'] })

    $ports.sort.each |$p| {
        ferm::service { "pontoon-lb-${p}":
            proto   => 'tcp',
            notrack => true,
            port    => $p,
        }
    }
}
