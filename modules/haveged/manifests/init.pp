# SPDX-License-Identifier: Apache-2.0
# @summary Manage and install haveged deamon
# @param buffer_size Buffer size [KW]
# @param data_cache Data cache size [KB]
# @param instruction_cache Instruction cache size [KB]
# @param write_wakeup_threshold The write_wakeup_threshold
class haveged (
    Integer $buffer_size = 128,
    Integer $data_cache = 16,
    Integer $instruction_cache = 16,
    Integer $write_wakeup_threshold = 1024
) {
    ensure_packages(['haveged'])
    $default_haveged = @("CONF")
    # Managed by Puppet!
    DAEMON_ARGS="-b ${buffer_size} \
        -d ${data_cache} \
        -i ${instruction_cache} \
        -w ${write_wakeup_threshold}"
    | CONF
    file {'/etc/default/haveged':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => $default_haveged,
        notify  => Service['haveged'],
    }
    service{ 'haveged':
        ensure => running,
        enable => true,
    }
}
