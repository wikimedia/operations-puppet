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
    Array $project_masters = lookup('profile::openstack::eqiad1::cumin::project_masters'),
    $project_pub_key = lookup('profile::openstack::eqiad1::cumin::project_pub_key'),
    $cluster = lookup('cluster'),
    $site = $::site,  # lint:ignore:wmf_styleguide
    Array[Stdlib::IP::Address] $cumin_masters = lookup('cumin_masters', {'default_value' => []}),
) {
    require ::network::constants

    # Include cumin::selector on all cumin targets so that
    # the get_clusters puppet function will get results when calling
    # query_resources.
    class { '::cumin::selector':
        cluster => $cluster,
        site    => $site,
    }

    $ssh_authorized_sources = join($cumin_masters, ',')
    $project_masters_str = join($project_masters, ',')
    $pub_key = secret('keyholder/cumin_openstack_master.pub')

    ssh::userkey { 'root-cumin':
        ensure  => present,
        user    => 'root',
        skey    => 'cumin',
        content => template('profile/openstack/eqiad1/cumin/userkey.erb'),
    }

    if $project_masters_str != '' {
        ferm::conf { 'cumin-project-defs':
            content => "@def \$CUMIN_MASTERS = (${cumin_masters.join(' ')} ${project_masters_str});\n",
            prio    => '01',
        }
    }

    # Wrapper used by cumin to reboot hosts without losing the ssh connection
    file { '/usr/local/sbin/reboot-host':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
        source => 'puppet:///modules/cumin/reboot-host',
    }
}
