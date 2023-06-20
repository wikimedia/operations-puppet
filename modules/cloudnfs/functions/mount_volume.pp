# SPDX-License-Identifier: Apache-2.0
# @summary get where a specific NFS mount should be mounted on this host
function cloudnfs::mount_volume (
    String[1] $mount,
) >> Variant[Boolean, String[1]] {
    include cloudnfs::volume_data
    $project_config = $cloudnfs::volume_data::projects[$::wmcs_project]
    $project_config.dig('mounts', $mount).lest || { false }
}
