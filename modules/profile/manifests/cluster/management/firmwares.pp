# SPDX-License-Identifier: Apache-2.0
#
# Configure a simple rsync workflow to keep Dcops
# host firmwares (BIOS/BMC/SSD/etc..) in sync between
# the cluster management hosts.
#
# === Parameters
#
# [*source_host*] What cumin host are we copying data from.
# [*dest_host*] What cumin nodes are we copying data to.
#
class profile::cluster::management::firmwares(
    Stdlib::Fqdn $source_host = lookup('profile::cluster::management::firmwares::source_host'),
    Variant[Stdlib::Host,
            Array[Stdlib::Host, 1]] $dest_host = lookup('profile::cluster::management::firmwares::dest_hosts'),
) {
    rsync::quickdatacopy { 'srv_firmwares':
        source_host         => $source_host,
        dest_host           => $dest_host,
        module_path         => '/srv/firmware',
        auto_sync           => true,
        server_uses_stunnel => true,
        delete              => true,
    }
}
