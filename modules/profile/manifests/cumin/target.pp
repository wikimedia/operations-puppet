# SPDX-License-Identifier: Apache-2.0
# @summary
#   Parameters here are just a hotfix to the issue of not being able to select
#   by cluster/role/site easily, and also allows to add arbitrary tags to single
#   servers or classes of servers.
#   Note that once the role/profile transition is complete, we should not need
#   those anymore.
# @param cluster the server cluster
# @param site the server site
# @param cumin_masters List of cumin masters
class profile::cumin::target(
    String $cluster = lookup('cluster'),
    String $site = $::site,
    Array[Stdlib::IP::Address] $cumin_masters = lookup('cumin_masters', {'default_value' => []}),
) {
    if defined('$::_role') {
        $roles = [regsubst($::_role, '/', '::', 'G')]
    } else {
        $roles = []
    }

    tag $roles

    require network::constants

    # Include cumin::selector on all cumin targets so that
    # the wmflib::get_clusters puppet function will get results when calling
    # wmflib::puppetdb_query.
    class { 'cumin::selector':
        cluster => $cluster,
        site    => $site,
    }

    # Make sure only managed keys are available in this file.
    # This will ensure that any hosts that accidentally add the cloud_production
    # profile will have the cloud-cumin key removed when they no longer use that
    # profile.
    file { '/etc/ssh/userkeys/root.d':
        ensure  => directory,
        purge   => true,
        recurse => true,
    }

    $ssh_authorized_sources = join($cumin_masters, ',')
    $cumin_master_pub_key = secret('keyholder/cumin_master.pub')

    ssh::userkey { 'root-cumin':
        ensure  => present,
        user    => 'root',
        skey    => 'cumin',
        content => template('profile/cumin/userkey.erb'),
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
