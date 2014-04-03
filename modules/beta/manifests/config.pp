# == Class: beta::config
#
# Shared configuration for beta classes
#
class beta::config {
    # IP address of deployment-bastion host
    $bastion_ip = '10.68.16.58'

    # Networks to allow for rsync
    $rsync_networks = [
        '10.68.16.0/21',  # labs-eqiad
    ]
}
