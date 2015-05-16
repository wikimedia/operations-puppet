# Class: labs_lvm
#
# Manages LVM in labs instance for extra storage.  labs_lvm
# only ensures the volume group exists, creating (and mounting)
# actual logical volumes is done with labs_lvm::volume resources.
#
# Parameters:
#   disk    => disk from which the LVM will be constructed
#              (as a physical partition spanning the last
#              unallocated segment of the disk)
#

class labs_lvm($disk = '/dev/vda') {

    package { 'lvm2':
        ensure => present,
    }

    file { '/usr/local/sbin/make-instance-vg':
        ensure  => file,
        source  => 'puppet:///modules/labs_lvm/make-instance-vg',
        require => Package['lvm2'],
        mode    => '0544',
        owner   => 'root',
        group   => 'root',
    }


    file { '/usr/local/sbin/make-instance-vol':
        ensure  => file,
        source  => 'puppet:///modules/labs_lvm/make-instance-vol',
        require => Package['lvm2'],
        mode    => '0544',
        owner   => 'root',
        group   => 'root',
    }

    file { '/usr/local/sbin/extend-instance-vol':
        ensure  => file,
        source  => 'puppet:///modules/labs_lvm/extend-instance-vol',
        require => Package['lvm2'],
        mode    => '0544',
        owner   => 'root',
        group   => 'root',
    }

    exec { 'create-volume-group':
        logoutput => 'on_failure',
        unless    => '/sbin/vgdisplay -c vd',
        require   => File['/usr/local/sbin/make-instance-vg'],
        command   => "/usr/local/sbin/make-instance-vg '${disk}'",
    }

}

