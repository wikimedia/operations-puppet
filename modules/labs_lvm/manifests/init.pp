# Class: labs_lvm
#
# Manages LVM in labs instance for extra storage.  labs_lvm
# only ensures the volume group exists, creating (and mounting)
# actual logical volumes is done with labs_lvm::volume.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#

class labs_lvm($disk) {

    package { 'lvm2':
        ensure      => present,
    }

    file { '/usr/local/sbin/make-instance-vg':
        ensure      => file,
        source      => 'puppet:///modules/labs_lvm/make-instance-vg',
        requires    => Package['lvm2'],
        mode        => 0544,
        owner       => 'root',
        group       => 'root',
    }

    exec { 'create-volume-group':
        creates     => '/dev/vd',
        requires    => File['/usr/local/sbin/make-instance-vg'],
        command     => "/usr/local/sbin/make-instance-vg '$disk'",
    }

}

