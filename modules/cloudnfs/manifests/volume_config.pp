# SPDX-License-Identifier: Apache-2.0
# @summary creates a nfs-mounts.yaml file
define cloudnfs::volume_config (
    Boolean          $host_scratch,
    String[1]        $owner  = 'root',
    String[1]        $group  = 'root',
    Stdlib::Filemode $mode   = '0444',
    Wmflib::Ensure   $ensure = 'present',
    Stdlib::Unixpath $path   = $title,
) {
    include cloudnfs::volume_data

    if $host_scratch {
        # A list of 'public' volumes hosted on this server. Public volumes
        # have permissive exports that let anyone attach.
        $public = {
            'scratch' => '/srv/scratch *(rw,sec=sys,sync,no_subtree_check,root_squash)',
        }
    } else {
        $public = {}
    }

    $data = {
        'public'  => $public,
        'private' => $cloudnfs::volume_data::projects,
    }

    file { $path:
        ensure  => stdlib::ensure($ensure, 'file'),
        content => $data.to_yaml,
        owner   => $owner,
        group   => $group,
        mode    => $mode,
    }
}
