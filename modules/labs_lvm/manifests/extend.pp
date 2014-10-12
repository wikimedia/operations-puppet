# resource: labs_lvm::volume
#
# labs_lvm::volume allocates a LVM volume from the volume group
# created by the labs_lvm class.
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
#   labs_lvm::volume { 'storage': mountat => '/mnt' }
#

define labs_lvm::extend(
    $mountat    = $title,
    $mountowner = 'root',
    $mountgroup = 'root',
    $mountmode  = '755',
    $size       = '100%FREE',
) {

    exec { "extend-vd-$mountat":
        logoutput   => 'on_failure',
        require     => [
                         File['/usr/local/sbin/extend-instance-vol'],
                       ],
        command     => "/usr/local/sbin/extend-instance-vol '$mountat' '$size'",
    }

}

