# == Class statistics::dataset_mount
# Mounts /data from dataset1001 server.
# xmldumps and other misc files needed
# for generating statistics are here.
#
# NOTE: This class has nothing to do with the
# datasets site hosted at 'datasets.wikimedia.org'.
#
class statistics::dataset_mount (
      $dumps_servers,
      $dumps_active_server,
  ){
    # need this for NFS mounts.
    require_package('nfs-common')

    file { '/mnt/data':
        ensure => 'absent',
    }

    mount { '/mnt/data':
        ensure  => 'absent',
        device  => '208.80.154.11:/data',
        fstype  => 'nfs',
        options => 'ro,bg,tcp,rsize=8192,wsize=8192,timeo=14,intr,addr=208.80.154.11',
        atboot  => true,
        require => File['/mnt/data'],
    }

    file {'/mnt/nfs':
        ensure => 'directory',
    }

    file { '/mnt/nfs/README':
        ensure  => 'present',
        source  => 'puppet:///modules/statistics/dumps-nfsmount-readme.txt',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => File['/mnt/nfs'],
    }

    $dumps_servers.each |String $server| {

        file { "/mnt/nfs/dumps-${server}":
            ensure => 'directory',
        }

        mount { "/mnt/nfs/dumps-${server}":
            ensure  => 'mounted',
            device  => "${server}:/dumps",
            fstype  => 'nfs',
            options => 'ro,bg,tcp,rsize=8192,wsize=8192,timeo=14,intr',
            atboot  => true,
            require => File["/mnt/nfs/dumps-${server}"],
        }
    }
}
