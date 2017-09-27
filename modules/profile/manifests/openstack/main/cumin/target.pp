# == profile::openstack::main::cumin::master
#
# Profile to allow a Cumin master for WMCS or a specific Cloud VPS project to
# connect to this Cloud VPS instance.
#
# === Hiera Parameters required for a project-specific Cumin target
#
# [*profile::openstack::main::cumin::project_masters*]
#   An array with the list of IPs of the Cumin master(s)
#
# [*profile::openstack::main::cumin::project_pub_key*]
#   The SSH public key used by Cumin master
#
class profile::openstack::main::cumin::target(
    $auth_group = hiera('profile::openstack::main::cumin::auth_group'),
    $project_masters = hiera('profile::openstack::main::cumin::project_masters'),
    $project_pub_key = hiera('profile::openstack::main::cumin::project_pub_key'),
) {
    require ::network::constants

    validate_array($project_masters)

    if $auth_group == 'cumin_masters' {
        $ssh_authorized_sources_list = $::network::constants::special_hosts[$::realm][$auth_group]
    } else {
        # Authorize both the default cumin masters and the custom config, required for proxies.
        $ssh_authorized_sources_list = concat(
            $::network::constants::special_hosts[$::realm]['cumin_masters'],
            $::network::constants::special_hosts[$::realm][$auth_group])
    }

    $ssh_authorized_sources = join($ssh_authorized_sources_list, ',')
    $ssh_project_authorized_sources = join($project_masters, ',')
    $pub_key = secret('keyholder/cumin_openstack_master.pub')

    ssh::userkey { 'root-cumin':
        ensure  => present,
        user    => 'root',
        skey    => 'cumin',
        content => template('profile/openstack/main/cumin/userkey.erb'),
    }
}
