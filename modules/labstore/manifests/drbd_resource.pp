# This defines a puppet resource of type drbd_resource
# Defining a drbd resource with the given parameters creates
# a DRBD resource config file (<resource_name>.res) at the given path.
#
# Parameters:
#   $nodes: Array with 2 values containing the node names where the resources are
#           meant to be available. Typically one of these nodes will be designated
#           primary, and the other secondary.
#   $port: Integer port number for DRBD TCP connections. Needs to be unique for
#          every resource, by convention DRBD uses TCP ports from 7788 upwards.
#   $device: Path for the DRBD device
#   $disk: Path for underlying volume on disk
#   $path: Path where the resource config should be created, /etc/drbd.d by
#          default.
#
# Example:
# labstore::drbd_resource {'maps':
#     nodes  => ['labstore1004', 'labstore1005'],
#     port   => 7788,
#     device => '/dev/drbd1',
#     disk   => '/dev/misc/maps',
#     notify => Exec['drbdadm-adjust'],
# }
#
define labstore::drbd_resource (
    $nodes,
    $port,
    $device,
    $disk,
    $path = '/etc/drbd.d',
) {

    file { "${path}/${title}.res":
        content => template('labstore/drbd/drbd_resource.res.erb'),
          # This template can access all of the parameters and variables from above.
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }
}
