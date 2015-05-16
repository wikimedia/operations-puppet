# resource: labs_lvm::extend
#
# labs_lvm::extend ensures the specified volume has at least
# the requested size (if possible)
#
# Parameters:
#   mountat  => point where the volume is to be mounted; defaults
#               to the title
#   size     => desired size of the volume, using the lvcreate(8)
#               syntax.  This can only /extend/ the volume size.
#
# Requires:
#   The node must have included the labs_lvm class.
#
# Sample Usage:
#   labs_lvm::extend { '/srv': size => '8G' }
#

define labs_lvm::extend(
    $mountat    = $title,
    $mountowner = 'root',
    $mountgroup = 'root',
    $mountmode  = '755',
    $size       = '100%FREE',
) {

    exec { "extend-vd-${mountat}":
        logoutput => 'on_failure',
        require   => File['/usr/local/sbin/extend-instance-vol'],
        command   => "/usr/local/sbin/extend-instance-vol '${mountat}' '${size}'",
    }

}

