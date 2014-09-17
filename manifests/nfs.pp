# nfs.pp

# Virtual resource for the monitoring server
#@monitor_group { "nfs": description => "NFS" }

class nfs::common {
    package { 'nfs-common':
        ensure => 'latest',
    }
}

class nfs::server {

    include nfs::common

    package { 'nfs-kernel-server':
        ensure => 'latest',
    }

    if $static_nfs {
        file { '/etc/default/nfs-common':
            ensure  => 'present',
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            source  => 'puppet:///files/nfs/nfs-common',
            require => Package['nfs-common'],
        }

        file { '/etc/default/nfs-kernel-server':
            ensure  => 'present',
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            source  => 'puppet:///files/nfs/nfs-kernel-server',
            require => Package['nfs-kernel-server'],
        }

        file { '/etc/default/quota':
            ensure  => 'present',
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            source  => 'puppet:///files/nfs/quota',
            require => Package['nfs-kernel-server'],
        }

        file { '/etc/modprobe.d/lockd.conf':
            ensure  => 'present',
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            source  => 'puppet:///files/nfs/lockd.conf',
            require => Package['nfs-kernel-server'],
        }

    }

}

class nfs::home {
    include nfs::common
    include nfs::home::wikipedia

    # Class admins tests whether Mount["/home"] is defined
    mount { '/home':
        ensure  => 'mounted',
        device  => '10.0.5.8:/home',
        fstype  => 'nfs',
        name    => '/home',
        options => 'bg,tcp,rsize=8192,wsize=8192,timeo=14,intr',
    }
}

# Classes for NetApp mounts used on multiple servers

class nfs::netapp::common {
    include nfs::common

    $device = $::site ? {
        'pmtpa'   => 'nas1-a.pmtpa.wmnet',
        'eqiad'   => 'nas1001-a.eqiad.wmnet',
        default => undef,
    }

    $options = 'bg,intr'
}

class nfs::netapp::home($ensure='mounted', $mountpoint='/home') {
    include common

    file { $mountpoint:
        ensure => 'directory',
    }

    mount { $mountpoint:
        ensure  => $ensure,
        require => File[$mountpoint],
        device  => "${nfs::netapp::common::device}:/vol/home_${::site}",
        fstype  => 'nfs',
        options => $nfs::netapp::common::options,
    }
}

class nfs::netapp::home::othersite($ensure='mounted', $mountpoint=undef) {
    include common

    $peersite = $::site ? {
        'pmtpa' => 'eqiad',
        'eqiad' => 'pmtpa',
        default => undef
    }
    $path = $mountpoint ? {
        undef   => "/srv/home_${peersite}",
        default => $mountpoint
    }

    file { $path:
        ensure => 'directory',
    }

    mount { $path:
        ensure  => $ensure,
        require => File[$path],
        device  => "${nfs::netapp::common::device}:/vol/home_${peersite}",
        fstype  => 'nfs',
        options => "${nfs::netapp::common::options},ro",
    }
}

# Historical /home/wikipedia
class nfs::home::wikipedia {

    case $::realm {
        'production': {
            require nfs::home
            file { '/home/wikipedia':
                ensure => 'directory',
                mode   => '0755',
                owner  => 'root',
                group  => 'root',
            }
        } # /production
        'labs': {

            group { 'wikipediauser':
                ensure => present,
                name   => 'wikipediauser',
                system => true,
            }

            user { 'wikipediauser':
                home       => '/home/wikipedia',
                managehome => true,
                system     => true,
            }

            file { '/home/wikipedia':
                ensure  => 'directory',
                require => User['wikipediauser'],
            }
        }
    }

}

class nfs::data {
    include nfs::common

    file { [ '/mnt/data' ]:
        ensure => 'directory',
    }

        $datasetserver = $::site ? {
            'eqiad' => 'dataset1001.wikimedia.org',
            'pmtpa' => 'dataset2.wikimedia.org',
            default => 'dataset2.wikimedia.org',
        }

    mount { '/mnt/data':
        ensure   => 'mounted',
        device   => "${datasetserver}:/data",
        fstype   => 'nfs',
        name     => '/mnt/data',
        options  => 'bg,hard,tcp,rsize=8192,wsize=8192,intr,nfsvers=3',
        require  => File['/mnt/data'],
        remounts => false,
    }
}

class nfs::netapp::fr_archive(
        $ensure= 'mounted',
        $mountpoint= '/archive/udplogs'
    ) {

    include common

    file { $mountpoint:
        ensure => 'directory',
    }

    mount { $mountpoint:
        ensure  => $ensure,
        require => File[$mountpoint],
        device  => "${nfs::netapp::common::device}:/vol/fr_archive",
        fstype  => 'nfs',
        options => $nfs::netapp::common::options,
    }
}

# moved here from misc-servers.pp
class misc::nfs-server::home {
    system::role { 'misc::nfs-server::home': description => '/home NFS' }

    class backup {
        cron { 'home-rsync':
            ensure  => 'absent',
            require => File['/root/.ssh/home-rsync'],
            command => '[ -d /home/wikipedia ] && rsync --rsh="ssh -c blowfish-cbc -i /root/.ssh/home-rsync" -azu /home/* db20@tridge.wikimedia.org:~/home/',
            user    => 'root',
            hour    => 2,
            minute  => 35,
            weekday => 6,
        }

        file { '/root/.ssh/home-rsync':
            owner  => 'root',
            group  => 'root',
            mode   => '0400',
            source => 'puppet:///private/backup/ssh-keys/home-rsync',
        }
    }

    package { 'nfs-kernel-server':
        ensure => 'latest',
    }

    file { '/etc/exports':
        require => Package['nfs-kernel-server'],
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///files/nfs/exports.home',
    }

    service { 'nfs-kernel-server':
        require   => [ Package['nfs-kernel-server'], File['/etc/exports'] ],
        subscribe => File['/etc/exports'],
    }

    class monitoring {
        monitor_service { 'nfs': description => 'NFS', check_command => 'check_tcp!2049' }
    }

    include monitoring
}

class misc::nfs-server::home::rsyncd {
    system::role { 'misc::nfs-server::home::rsyncd': description => '/home rsync daemon' }

    include rsync::server
    include network::constants

    rsync::server::module { 'httpdconf':
        path        => '/home/wikipedia/conf/httpd',
        read_only   => 'yes',
        hosts_allow => $::network::constants::mw_appserver_networks,
    }
}
