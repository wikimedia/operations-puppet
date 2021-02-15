# Common ferm class for labstore servers.

class profile::wmcs::nfs::ferm {
    ferm::service { 'labstore_nfs_nfs_service':
        proto  => 'tcp',
        port   => '2049',
        srange => '(($LABS_NETWORKS $CLOUD_NETWORKS_PUBLIC))',
    }
}
