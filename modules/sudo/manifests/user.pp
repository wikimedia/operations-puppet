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
    $privileges,
    $ensure = present,
    $user   = $title,
) {
    validate_ensure($ensure)

    $title_safe = regsubst($title, '\W', '-', 'G')

    file { "/etc/sudoers.d/${title_safe}":
        ensure  => $ensure,
        content => template('sudo/sudoers.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
    }
}
