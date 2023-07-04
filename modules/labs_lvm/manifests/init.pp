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

class labs_lvm(
    Stdlib::Unixpath $disk      = '/dev/sda',
    Boolean          $ephemeral = false,
) {

    package { ['lvm2', 'parted']:
        ensure => present,
    }

    file { '/usr/local/sbin/make-instance-vg':
        ensure  => file,
        source  => 'puppet:///modules/labs_lvm/make-instance-vg.sh',
        require => Package['lvm2', 'parted'],
        mode    => '0544',
        owner   => 'root',
        group   => 'root',
    }

    file { '/usr/local/sbin/make-instance-vg-ephem':
        ensure  => file,
        source  => 'puppet:///modules/labs_lvm/make-instance-vg-ephem.sh',
        require => Package['lvm2'],
        mode    => '0544',
        owner   => 'root',
        group   => 'root',
    }

    file { '/usr/local/sbin/pv-free':
        ensure  => file,
        source  => 'puppet:///modules/labs_lvm/pv-free.py',
        require => Package['lvm2', 'parted'],
        mode    => '0544',
        owner   => 'root',
        group   => 'root',
    }

    file { '/usr/local/sbin/make-instance-vol':
        ensure  => file,
        source  => 'puppet:///modules/labs_lvm/make-instance-vol.sh',
        require => Package['lvm2'],
        mode    => '0544',
        owner   => 'root',
        group   => 'root',
    }

    file { '/usr/local/sbin/extend-instance-vol':
        ensure  => file,
        source  => 'puppet:///modules/labs_lvm/extend-instance-vol.sh',
        require => Package['lvm2'],
        mode    => '0544',
        owner   => 'root',
        group   => 'root',
    }

    if $ephemeral {
        exec { 'create-volume-group':
            logoutput => 'on_failure',
            unless    => '/sbin/vgdisplay -c vd',
            require   => File['/usr/local/sbin/make-instance-vg-ephem'],
            command   => "/usr/local/sbin/make-instance-vg-ephem '${disk}'",
        }
    } else {
        exec { 'create-volume-group':
            logoutput => 'on_failure',
            unless    => '/sbin/vgdisplay -c vd',
            require   => File['/usr/local/sbin/make-instance-vg'],
            command   => "/usr/local/sbin/make-instance-vg '${disk}'",
        }
    }
}

