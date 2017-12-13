# === Class role::cluster::management
#
# This class setup a host to be a cluster manager, including all the tools,
# automation and orchestration softwares, ACL and such.
#
class role::cluster::management {

    system::role { 'cluster-management':
        description => 'Cluster management',
    }

    include ::profile::mariadb::wmf_root_client
    include ::role::cumin::master
    include ::role::ipmi::mgmt
    include ::role::access_new_install
    include ::profile::conftool::client
    include ::profile::switchdc
    include ::profile::debdeploy
    include ::standard
    include ::base::firewall
}
