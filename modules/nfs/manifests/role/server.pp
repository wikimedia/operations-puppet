import "generic.pp"

# moved here from misc-servers.pp
class nfs::role::server::home {
    system_role { "nfs::role::server::home": description => "/home NFS" }

    package { nfs-kernel-server:
        ensure => latest;
    }

    file { "/etc/exports":
        require => Package[nfs-kernel-server],
        mode => 0444,
        owner => root,
        group => root,
        source => "puppet:///modules/nfs/exports.home";
    }

    service { nfs-kernel-server:
        require => [ Package[nfs-kernel-server], File["/etc/exports"] ],
        subscribe => File["/etc/exports"];
    }

    monitor_service { "nfs": description => "NFS", check_command => "check_tcp!2049" }
}

class nfs::role::server::home::backup {
    cron { home-rsync:
        require => File["/root/.ssh/home-rsync"],
        command => '[ -d /home/wikipedia ] && rsync --rsh="ssh -c blowfish-cbc -i /root/.ssh/home-rsync" -azu /home/* db20@tridge.wikimedia.org:~/home/',
        user => root,
        hour => 2,
        minute => 35,
        weekday => 6,
        ensure => present;
    }

    file { "/root/.ssh/home-rsync":
        owner => root,
        group => root,
        mode => 0400,
        source => "puppet:///private/backup/ssh-keys/home-rsync";
    }
}

class nfs::role::server::home::rsyncd {
    system_role { "nfs::role::server::home::rsyncd": description => "/home rsync daemon" }

    class { 'generic::rsyncd': config => "home" }
}
