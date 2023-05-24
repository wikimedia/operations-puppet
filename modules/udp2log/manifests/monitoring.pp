# SPDX-License-Identifier: Apache-2.0
# @summary add scripts for monitoring
# @param enabled indicate if monitoring is enabled
class udp2log::monitoring (
    Boolean $enabled = true
) {
    file {
        default:
            ensure => stdlib::ensure($enabled, 'file'),
            mode   => '0555',
            owner  => 'root',
            group  => 'root';
        '/usr/lib/nagios/plugins/check_udp2log_log_age':
            source => 'puppet:///modules/udp2log/check_udp2log_log_age';
        '/usr/lib/nagios/plugins/check_udp2log_procs':
            source => 'puppet:///modules/udp2log/check_udp2log_procs';
    }
}
