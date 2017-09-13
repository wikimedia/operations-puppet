class profile::openstack::main::cumin::target(
    $authorized_group = hiera('profile::openstack::main::cumin_auth_group'),
) {
    require ::network::constants

    $ssh_authorized_sources = join($::network::constants::special_hosts[$::realm][$authorized_group], ',')
    $cumin_master_pub_key = secret('keyholder/cumin_openstack_master.pub')

    ssh::userkey { 'root-cumin':
        ensure  => present,
        user    => 'root',
        skey    => 'cumin',
        content => template('profile/openstack/main/cumin/userkey.erb'),
    }
}
