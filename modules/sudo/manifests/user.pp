# SPDX-License-Identifier: Apache-2.0
# == Define: sudo::user
#
# Manages a sudo specification in /etc/sudoers.d.
#
# === Parameters
#
# [*privileges*]
#   Array of sudo privileges.
#
# [*user*]
#   User to which privileges should be assigned.
#   Defaults to the resource title.
#
# === Examples
#
#  sudo::user { 'nagios_check_raid':
#    user       => 'nagios',
#    privileges => [
#      'ALL = NOPASSWD: /usr/local/lib/nagios/plugins/check-raid'
#    ],
#  }
#
define sudo::user(
    Array[String] $privileges            = [],
    $ensure                              = present,
    $user                                = $title,
) {
    # TODO: remove once Stretch is gone from Cloud VPS
    if $::realm != 'labs' or debian::codename::ge('buster') {
        require sudo
    } else {
        require sudo::sudoldap
    }

    $title_safe = regsubst($title, '\W', '-', 'G')
    $filename = "/etc/sudoers.d/${title_safe}"

    if $ensure == 'present' {
        file { $filename:
            ensure       => $ensure,
            owner        => 'root',
            group        => 'root',
            mode         => '0440',
            content      => template('sudo/sudoers.erb'),
            validate_cmd => '/usr/sbin/visudo -cqf %',
        }
    } else {
        file { $filename:
            ensure => $ensure,
        }
    }
}
