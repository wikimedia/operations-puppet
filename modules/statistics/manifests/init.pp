#This class sets the basic parts of the statistics module
class statistics {
    $username = 'stats'
    $homedir  = "/var/lib/${username}"

    generic::systemuser { $username:
        name   => $username,
        home   => $homedir,
        groups => 'wikidev',
        shell  => '/bin/bash',
    }

    # create a .gitconfig file for stats user
    file { "${homedir}/.gitconfig":
        mode    => '0664',
        owner   => $username,
        content => "[user]\n\temail = otto@wikimedia.org\n\tname = Statistics User",
    }

    include statistics::packages
    include statistics::firewall

    file { '/a':
        ensure  => 'directory',
        owner   => 'root',
        group   => 'wikidev',
        mode    => '0775',
        recurse => false,
    }

    # Mounts /data from dataset2 server.
    # xmldumps and other misc files needed
    # for generating statistics are here.
    # need this for NFS mounts.

    include nfs::common

    file { '/mnt/data':
        ensure => 'directory',
    }

    mount { '/mnt/data':
        ensure  => mounted,
        device  => '208.80.152.185:/data',
        fstype  => 'nfs',
        options => 'ro,bg,tcp,rsize=8192,wsize=8192,timeo=14,intr,addr=208.80.152.185',
        atboot  => true,
        require => [File['/mnt/data'], Class['nfs::common']],
    }

# installs MonogDB on stat1
    class { 'mongodb':
        dbpath    => '/a/mongodb',
    }
}

