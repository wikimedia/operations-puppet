# main tools-grid-master.tools.eqiad.wmflabs
class profile::openstack::base::pdns::auth::monitor::host_check(
    $auth_soa_name = hiera('profile::openstack::base::pdns::host'),
    $target_fqdn = hiera('profile::openstack::base::pdns::monitor::target_fqdn'),
    ) {

    monitoring::host { $auth_soa_name:
        ip_address => $::ipaddress,
    }

    monitoring::service { "${auth_soa_name} Auth DNS UDP":
        host          => $auth_soa_name,
        description   => 'Check for gridmaster host resolution UDP',
        check_command => "check_dig!${auth_soa_name}!${target_fqdn}",
    }

    monitoring::service { "${auth_soa_name} Auth DNS TCP":
        host          => $auth_soa_name,
        description   => 'Check for gridmaster host resolution TCP',
        check_command => "check_dig_tcp!${auth_soa_name}!${target_fqdn}",
    }
}
