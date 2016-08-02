# Class that defines the basics for a DRBD node setup.
# It sets up the required packages, and the global configuration for DRBD.
# Once this class is applied, DRBD resources can then be defined by using
# the labstore::drbd_resource define type.
# The service management is also expected to happen outside this class.
#
# Parameters
#   $path: Path where the global common config should be created, /etc/drbd.d by
#          default.
#
class labstore::drbd_node (
    $path = '/etc/drbd.d',
) {

    # Make sure drbd is installed
    # Installing this package also sets up a systemd init script in /etc/init.d
    ensure_packages(['drbd8-utils',])

    # Setup global config that is shared for all DRBD resources on this node
    file { "${path}/global_common.conf":
        ensure  => present,
        content => template('labstore/drbd/global_common.conf.erb'),
    }

}
