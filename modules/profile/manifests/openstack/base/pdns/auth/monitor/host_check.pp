class profile::openstack::base::pdns::auth::monitor::host_check(
    $target_host = hiera('profile::openstack::base::pdns::host'),
    $target_fqdn = hiera('profile::openstack::base::pdns::monitor::target_fqdn'),
    ) {

    monitoring::service { "${target_host} Resolution":
        description   => 'Auth DNS',
        check_command => "check_dns!${target_host}",
    }

    monitoring::service { "${target_host} Auth DNS UDP":
        description   => 'Check for gridmaster host resolution UDP',
        check_command => "check_dig!${target_host}!${target_fqdn}",
    }

    monitoring::service { "${target_host} Auth DNS TCP":
        description   => 'Check for gridmaster host resolution TCP',
        check_command => "check_dig_tcp!${target_host}!${target_fqdn}",
    }
}
