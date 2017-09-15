# Firewall rules for the misc db host used by wmcs.  We need special
#  rules to allow access for openstack services (which typically
#  run on hosts with public IPs)

class role::mariadb::ferm_wmcs {
    $nova_controller = hiera('profile::openstack::main::nova_controller')
    $nova_controller_standby = hiera('profile::openstack::main::nova_controller_standby')
    ferm::service{ 'nova_controller':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => "${nova_controller} ${nova_controller_standby}",
    }

    $designate_host = hiera('profile::openstack::main::designate_host')
    $designate_host_standby = hiera('profile::openstack::main::designate_host_standby')
    ferm::service{ 'designate':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => "${designate_host} ${designate_host_standby}",
    }

    ferm::service{ 'wmcs_puppetmasters':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '@resolve((labpuppetmaster1001.wikimedia.org)) @resolve((labpuppetmaster1002.wikimedia.org))',
    }

    ferm::service{ 'striker':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '@resolve((toolsadmin.wikimedia.org))',
    }

    ferm::service{ 'wikitech':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '@resolve((wikitech.wikimedia.org))',
    }
}
