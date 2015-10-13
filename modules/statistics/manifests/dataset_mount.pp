# == Class statistics::dataset_mount
# Mounts /data from dataset1001 server.
# xmldumps and other misc files needed
# for generating statistics are here.
#
# NOTE: This class has nothing to do with the
# datasets site hosted at 'datasets.wikimedia.org'.
#
class statistics::dataset_mount {
    # need this for NFS mounts.
    require_package('nfs-common')

    file { '/mnt/data':
        ensure => 'directory',
    }

    mount { '/mnt/data':
        ensure  => 'mounted',
        device  => '208.80.154.11:/data',
        fstype  => 'nfs',
        options => 'ro,bg,tcp,rsize=8192,wsize=8192,timeo=14,intr,addr=208.80.154.11',
        atboot  => true,
        require => File['/mnt/data'],
    }
}
