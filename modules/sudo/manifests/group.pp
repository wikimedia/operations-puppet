# == Define: sudo::group
#
# Manages a sudo specification in /etc/sudoers.d.
#
# === Parameters
#
# [*privileges*]
#   Array of sudo privileges.
#
# [*group*]
#   User to which privileges should be assigned.
#   Defaults to the resource title.
#
# === Examples
#
#  sudo::group { 'nagios_check_raid':
#    group       => 'nagios',
#    privileges => [
#      'ALL = NOPASSWD: /usr/local/lib/nagios/plugins/check-raid'
#    ],
#  }
#
define sudo::group(
    $privileges,
    $ensure  = present,
    $group   = $title,
) {
    require sudo

    validate_ensure($ensure)

    $title_safe = regsubst($title, '\W', '-', 'G')

    file { "/etc/sudoers.d/${title_safe}":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => template('sudo/sudoers.erb'),
    }
}
