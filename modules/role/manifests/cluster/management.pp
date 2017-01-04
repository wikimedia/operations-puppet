# === Class role::cluster::management
#
# This class setup a host to be a cluster manager, including all the tools,
# automation and orchestration softwares, ACL and such.
#
class role::cluster::management {

    system::role { 'cluster-management':
        description => 'Cluster management',
    }

    include ::role::salt::masters::production
    include ::role::mariadb::client
    include ::role::cumin::master
    include ::standard
    include ::base::firewall
}
