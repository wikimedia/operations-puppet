# Parameters here are just a hotfix to the issue of not being able to select
# by cluster/role/site easily, and also allows to add arbitrary tags to single
# servers or classes of servers.
# Note that once the role/profile transition is complete, we should not need
# those anymore.
class profile::cumin::target(
    $cluster = hiera('cluster', 'misc'),
    $site = $::site,
) {
    if $::_roles {
        $roles = prefix(keys($::_roles), 'role::')
    } else {
        $roles = []
    }

    tag $roles

    require ::network::constants

    $ssh_authorized_sources = join($::network::constants::special_hosts[$::realm]['cumin_masters'], ',')
    $cumin_master_pub_key = secret('keyholder/cumin_master.pub')

    ssh::userkey { 'root-cumin':
        ensure  => present,
        user    => 'root',
        skey    => 'cumin',
        content => template('profile/cumin/userkey.erb'),
    }
}
