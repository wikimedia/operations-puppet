class profile::openstack::main::cumin::target(
    $cumin_auth_group = hiera('profile::openstack::main::cumin_auth_group'),
) {
    require ::network::constants

    if $cumin_auth_group == 'cumin_masters' {
        $ssh_authorized_sources_list = $::network::constants::special_hosts[$::realm][$cumin_auth_group]
    } else {
        # Authorize both the default cumin masters and the custom config, required for proxies.
        $ssh_authorized_sources_list = concat(
            $::network::constants::special_hosts[$::realm]['cumin_masters'],
            $::network::constants::special_hosts[$::realm][$cumin_auth_group])
    }

    $ssh_authorized_sources = join($ssh_authorized_sources_list, ',')
    $cumin_master_pub_key = secret('keyholder/cumin_openstack_master.pub')

    ssh::userkey { 'root-cumin':
        ensure  => present,
        user    => 'root',
        skey    => 'cumin',
        content => template('profile/openstack/main/cumin/userkey.erb'),
    }
}
