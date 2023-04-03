# SPDX-License-Identifier: Apache-2.0
# @summary manage the log rotate service
# @param hourly By default logrotate runs daily via a systemd timer, if true it runs hourly instead
class profile::logrotate (
    Boolean $hourly = lookup('profile::logrotate::hourly'),
) {
    class { 'logrotate':
        * => wmflib::dump_params(),
    }
}
