# SPDX-License-Identifier: Apache-2.0
# a place to temporarily dump gitlab backups until
# we have the new physical hosts up and running (T274463)
class role::gitlab_dump {

    system::role { 'gitlab_dump':
        description => 'A place to dump gitlab backups',
    }

    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::backup::host
    include ::profile::gitlab::dump
}
