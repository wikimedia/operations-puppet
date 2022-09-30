# SPDX-License-Identifier: Apache-2.0

# see https://bugs.debian.org/989162
class bridge_utils::workaround_debian_bug_989162 (
) {
    debian::codename::require('bullseye')
    ensure_packages(['bridge-utils'])

    $src_patch_file = 'puppet:///modules/bridge_utils/bridge-utils.sh.patch'
    $file_to_patch  = '/lib/bridge-utils/bridge-utils.sh'
    $patch = "${file_to_patch}.patch"

    file { $patch:
        source => $src_patch_file,
    }

    exec { "patch ${file_to_patch} with ${patch}":
        command => "/usr/bin/patch --forward ${file_to_patch} ${patch}",
        unless  => "/usr/bin/patch --reverse --dry-run -f ${file_to_patch} ${patch}",
        require => File[$patch],
    }
}
