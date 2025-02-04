# SPDX-License-Identifier: Apache-2.0
class base::sysctl::inotify (
    Integer $max_user_watches   = 32768,
    Integer $max_user_instances = 512,
) {

    sysctl::parameters { 'increase_inotify_limits':
        values => {
            'fs.inotify.max_user_watches'   => $max_user_watches,
            'fs.inotify.max_user_instances' => $max_user_instances
        }
    }
}
