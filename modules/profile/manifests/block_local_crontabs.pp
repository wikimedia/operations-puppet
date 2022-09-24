# SPDX-License-Identifier: Apache-2.0
# @summary Prevents users from provisioning local crontabs on this host
class profile::block_local_crontabs () {
    # Block everyone except root from using `crontab` to install local
    # crontabs on this host. For more details, see crontab(1)
    file { '/etc/cron.allow':
        ensure  => file,
        content => "root\n",
    }
}
