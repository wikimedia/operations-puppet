# SPDX-License-Identifier: Apache-2.0
# Class: labs_lvm_ephemeral
#
# Create a single lvm volume group
#  on the ephemeral drive of a cloud-vps VM
#

class labs_lvm::ephemeral {

    ensure_packages(['lvm2', 'parted'])

    file { '/usr/local/sbin/make-instance-vg-ephem':
        ensure  => file,
        source  => 'puppet:///modules/labs_lvm/make-instance-vg-ephem.sh',
        require => Package['lvm2'],
        mode    => '0544',
        owner   => 'root',
        group   => 'root',
    }

    # This script applies to the first found ephemeral disk.
    exec { 'create-ephemeral-volume-group':
        logoutput => 'on_failure',
        unless    => '/sbin/vgdisplay -c vd',
        require   => File['/usr/local/sbin/make-instance-vg-ephem'],
        command   => '/usr/local/sbin/make-instance-vg-ephem',
    }
}

