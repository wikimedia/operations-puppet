class profile::hadoop::hdfs::mountpoint {

    # Mount HDFS via Fuse on Analytics client nodes.
    # This will mount HDFS at /mnt/hdfs read only.
    class { '::cdh::hadoop::mount': }

    exec { 'force-remount':
        command   => '/bin/umount /mnt/hdfs; /bin/mount /mnt/hdfs',
        onlyif    => 'ls /mnt/hdfs | grep -q "Transport not connected"',
        logoutput => true,
    }

}