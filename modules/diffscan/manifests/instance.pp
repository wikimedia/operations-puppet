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
) {
    include diffscan

    file { "${diffscan::base_dir}/targets-${title}.txt":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('diffscan/targets.txt.erb'),
    }

    $working_dir = "${diffscan::base_dir}/${title}"

    file { $working_dir:
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0775',
    }

    $command = "/usr/local/sbin/diffscan -p 1-65535 -E ${emailto} -W ${working_dir} ${diffscan::base_dir}/targets-${title}.txt"
    systemd::timer::job {"diffscan-${title}":
        user        => 'root',
        description => "Daily diffscan for ${title}",
        command     => $command,
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* 00:00:00',  # Every day at 12:00
        },
    }
}
