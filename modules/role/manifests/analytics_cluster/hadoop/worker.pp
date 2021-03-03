# == Class role::analytics_cluster::hadoop::worker
#
# filtertags: labs-project-analytics labs-project-math
class role::analytics_cluster::hadoop::worker {
    system::role { 'analytics_cluster::hadoop::worker':
        description => 'Hadoop Worker (DataNode & NodeManager)',
    }

    include ::profile::java
    include ::profile::hadoop::worker
    include ::profile::hadoop::worker::clients
    include ::profile::amd_gpu
    include ::profile::analytics::cluster::users
    include ::profile::kerberos::client
    include ::profile::kerberos::keytabs
    include ::profile::base::firewall

    # Notes about the kernel versions:
    # - 4.19 was added initially for GPU nodes, and then it was extended to all
    #   worker nodes as prep-step for Buster (that by default runs 4.19)
    # - 5.10 was added for GPU nodes only, to have a more up to date kernel and
    #   AMD GPU drivers.
    include ::profile::base::linux419
    include ::profile::base::linux510
    include ::profile::standard
}
