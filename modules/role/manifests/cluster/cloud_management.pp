# SPDX-License-Identifier: Apache-2.0
# === Class role::cluster::cloud_management
#
# This class setup a host to be a cumin/spicerack master host to manage the WMCS infrastructure,
# both in production and in the WMCS realm (Openstack VPS)
#
class role::cluster::cloud_management {

    system::role { 'cluster-cloud-management':
        description => 'Cluster management of WMCS hosts',
    }

    include profile::base::production
    include profile::firewall

    include profile::cumin::cloud_master
    include profile::spicerack
    include profile::wmcs::spicerack_config

    # Backup all of /srv
    include profile::backup::host
    include profile::cluster::management::backup
}
