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
    $ensure  = present,
    $user    = $title,
) {
    require sudo

    validate_ensure($ensure)

    $title_safe = regsubst($title, '\W', '-', 'G')
    $filename = "/etc/sudoers.d/${title_safe}"

    if $ensure == 'present' {
        file { $filename:
            ensure  => $ensure,
            owner   => 'root',
            group   => 'root',
            mode    => '0440',
            content => template('sudo/sudoers.erb'),
        }

        exec { "sudo_user_${title}_linting":
            command     => "/bin/rm -f ${filename} && /bin/false",
            unless      => "/usr/sbin/visudo -cqf ${filename}",
            refreshonly => true,
            subscribe   => File[$filename],
        }
    } else {
        file { $filename:
            ensure => $ensure,
        }
    }
}
