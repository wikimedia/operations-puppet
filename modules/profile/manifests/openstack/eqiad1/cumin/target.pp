# == profile::openstack::eqiad1::cumin::target
#
# Profile to allow a Cumin master for WMCS or a specific Cloud VPS project to
# connect to this Cloud VPS instance.
#
# === Hiera Parameters required for a project-specific Cumin target
#
# [*profile::openstack::eqiad1::cumin::project_masters*]
#   An array with the list of IPs of the Cumin master(s)
#
# [*profile::openstack::eqiad1::cumin::project_pub_key*]
#   The SSH public key used by Cumin master
#
class profile::openstack::eqiad1::cumin::target(
    $auth_group = hiera('profile::openstack::eqiad1::cumin::auth_group'),
    $project_masters = hiera('profile::openstack::eqiad1::cumin::project_masters'),
    $project_pub_key = hiera('profile::openstack::eqiad1::cumin::project_pub_key'),
    $cluster = hiera('cluster', 'misc'),
    $site = $::site,  # lint:ignore:wmf_styleguide
    Array[Stdlib::IP::Address] $cumin_masters = hiera('cumin_masters', []),
) {
    require ::network::constants

    # Include cumin::selector on all cumin targets so that
    # the get_clusters puppet function will get results when calling
    # query_resources.
    class { '::cumin::selector':
        cluster => $cluster,
        site    => $site,
    }

    validate_array($project_masters)

    if $auth_group == 'cumin_masters' {
        $ssh_authorized_sources_list = $cumin_masters
    } else {
        # Authorize both the default cumin masters and the custom config, required for proxies.
        $ssh_authorized_sources_list = concat(
            $cumin_masters,
            $::network::constants::special_hosts[$::realm][$auth_group])
    }

    $ssh_authorized_sources = join($ssh_authorized_sources_list, ',')
    $ssh_project_authorized_sources = join($project_masters, ',')
    $ssh_project_ferm_sources = join($project_masters, ' ')
    $pub_key = secret('keyholder/cumin_openstack_master.pub')

    ssh::userkey { 'root-cumin':
        ensure  => present,
        user    => 'root',
        skey    => 'cumin',
        content => template('profile/openstack/eqiad1/cumin/userkey.erb'),
    }

    if $ssh_project_ferm_sources != '' {
        ::ferm::service { 'ssh-from-cumin-project-masters':
            proto  => 'tcp',
            port   => '22',
            srange => "(${ssh_project_ferm_sources})",
        }
    }
}
