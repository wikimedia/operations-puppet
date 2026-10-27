# SPDX-License-Identifier: Apache-2.0
# backup::offsite provides any dependencies for offsite backups.
define backup::offsite(
    Wmflib::Ensure $ensure_packages = present,
) {
    stdlib::ensure_packages({
        'rclone' => {'ensure' => $ensure_packages}
    })
}
