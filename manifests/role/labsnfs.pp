# This is a transition role - Eventually this will end up
# in LDAP once transition is over.

class role::labsnfs::client {

    if $::site == 'pmtpa' {
        $nfscluster = 'labnfs.pmtpa.wmnet'

        file { '/etc/auto.master':
            ensure => file,
            owner => root,
            group => root,
            mode => 0444,
            content => template('labsnfs/auto.master.erb');
        }
        file { '/etc/auto.space':
            ensure => file,
            owner => root,
            group => root,
            mode => 0444,
            content => template('labsnfs/auto.space.erb');
        }
        file { '/etc/auto.time.home':
            ensure => file,
            owner => root,
            group => root,
            mode => 0444,
            content => template('labsnfs/auto.time.home.erb');
        }
        file { '/etc/auto.time.project':
            ensure => file,
            owner => root,
            group => root,
            mode => 0444,
            content => template('labsnfs/auto.time.project.erb');
        }

        file { '/etc/init/nfs-noidmap.conf':
            source => 'puppet:///files/nfs/upstart-nfs-noidmap.conf'
        }
    } else {
        warning('Outside of pmtpa the role::labsnfs::client class is deprecated and does nothing.')
    }
}

