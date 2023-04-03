# SPDX-License-Identifier: Apache-2.0
# @summary manage the log rotate service
# @param hourly By default logrotate runs daily via a systemd timer, if true it runs hourly instead
class logrotate (
    Boolean $hourly = false,
) {
    ensure_packages(['logrotate'])
    $hourly_content = @(CONTENT)
    [Timer]
    OnCalendar=
    OnCalendar=hourly
    |CONTENT
    systemd::unit { 'logrotate.timer:hourly-override':
        ensure   => $hourly.bool2str('present', 'absent'),
        unit     => 'logrotate.timer',
        override => true,
        content  => $hourly_content,
    }
}
