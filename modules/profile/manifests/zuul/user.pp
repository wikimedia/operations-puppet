# SPDX-License-Identifier: Apache-2.0
# set up system user and group for new zuul
class profile::zuul::user {

    systemd::sysuser { 'zuul':
        description       => 'zuul system user',
        id                => 923,
        additional_groups => ['docker'],
    }
}
