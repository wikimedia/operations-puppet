class profile::cumin::target() {
    include network::constants

    $ssh_authorized_sources = join($::network::constants::special_hosts[$::realm]['cumin_masters'], ',')
    $cumin_master_pub_key = secret('keyholder/cumin_master.pub')

    ssh::userkey { 'root-cumin':
        ensure  => present,
        user    => 'root',
        skey    => 'cumin',
        content => template('profile/cumin/userkey.erb'),
    }
}
