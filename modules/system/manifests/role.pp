# == Define: system::role
#
# Adds a banner message to the server MOTD (usually displayed on login)
# that identifies the role of the server.
#
# === Parameters
#
# [*ensure*]
#   Present or absent. (Default: present.)
#
# [*description*]
#   A human-readable description of the role. Optional.
#
# === Example
#
#  system::role { 'role::analytics::hadoop::master':
#    description => 'Hadoop Master (NameNode & ResourceManager)'
#  }
#
define system::role(
    $ensure      = present,
    $description = undef,
) {
    $safename = regsubst($title, '\W', '-', 'G')

    $message = $description ? {
        undef   => "${::hostname} is ${title}",
        default => "${::hostname} is a ${description} (${title})",
    }

    # deactivated for now because it blocks new installs
    # dependency on minion config and having a signed salt key
    # salt::grain { $rolename: grain => 'rolename', value => $name }

    file { "/etc/update-motd.d/05-role-${safename}":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => "#!/bin/sh\necho '${message}'\n",
    }
}
