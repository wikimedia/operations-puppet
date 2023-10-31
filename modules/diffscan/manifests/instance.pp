# SPDX-License-Identifier: Apache-2.0
# == Define: diffscan
#
# This resource manages a single diffscan isntance.
#
# == Parameters
#
# [*ipranges*]
#   The list of IP/masks to scan. See nmap doc for accepted formats.
#
# [*emailto*]
#   Diff emails recipient.
#
define diffscan::instance (
    Array[Stdlib::IP::Address] $ipranges,
    Stdlib::Email              $emailto,
    String                     $groupname = $title,
) {
    include diffscan

    file { "${diffscan::base_dir}/targets-${groupname}.txt":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('diffscan/targets.txt.erb'),
    }
    $command = "/usr/local/sbin/diffscan -p 1-65535 -E ${emailto} -W ${diffscan::base_dir} ${diffscan::base_dir}/targets-${groupname}.txt"
    systemd::timer::job {"diffscan-${groupname}":
        user        => 'root',
        description => "Daily diffscan for ${groupname}",
        command     => $command,
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* 00:00:00',  # Every day at 12:00
        },
    }
}
