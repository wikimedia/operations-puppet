
class role::labs::instance {

    include "ldap::role::client::labs"

    if $::site == "eqiad" {
        service { 'autofs': ensure => stopped }  # Temporary measure to kill extant ones

        $nfs_opts = "vers=4,bg,hard,intr,sec=sys,proto=tcp,port=0,noatime"
        $nfs_server = "labstore.svc.eqiad.wmnet"

        mount { "/home":
            ensure => mounted, atboot => true, fstype => 'nfs', options => "rw,${nfs_opts}",
            device => "${nfs_server}:/project/${instanceproject}/home",
        }

        file { "/data":
            ensure => directory, owner => 'root', group => 'root', mode => '0755',
        }

        file { "/data/project":
            ensure => directory, owner => 'root', group => 'root', mode => '0755',
            require => File['/data'],
        }
        mount { "/data/project":
            ensure => mounted, atboot => true, fstype => 'nfs', options => "rw,${nfs_opts}",
            device => "${nfs_server}:/project/${instanceproject}/project",
            require => File['/data/project'],
        }

        file { "/data/scratch":
            ensure => directory, owner => 'root', group => 'root', mode => '0755',
            require => File['/data'],
        }
        mount { "/data/scratch":
            ensure => mounted, atboot => true, fstype => 'nfs', options => "rw,${nfs_opts}",
            device => "${nfs_server}:/scratch",
            require => File['/data/scratch'],
        }


        file { "/public":
            ensure => directory, owner => 'root', group => 'root', mode => '0755',
        }

        file { "/public/dumps":
            ensure => directory, owner => 'root', group => 'root', mode => '0755',
            require => File['/public'],
        }
        mount { "/public/dumps":
            ensure => mounted, atboot => true, fstype => 'nfs', options => "ro,${nfs_opts}",
            device => "${nfs_server}:/dumps",
            require => File['/public/dumps'],
        }

        file { "/public/backups":
            ensure => directory, owner => 'root', group => 'root', mode => '0755',
            require => File['/public'],
        }
        mount { "/public/backups":
            ensure => mounted, atboot => true, fstype => 'nfs', options => "ro,${nfs_opts}",
            device => "${nfs_server}:/backups",
            require => File['/public/backups'],
        }


        file { "/public/keys":
            ensure => directory, owner => 'root', group => 'root', mode => '0755',
            require => File['/public'],
        }
        mount { "/public/keys":
            ensure => mounted, atboot => true, fstype => 'nfs', options => "ro,${nfs_opts}",
            device => "${nfs_server}:/keys",
            require => File['/public/keys'],
        }


    }
}

