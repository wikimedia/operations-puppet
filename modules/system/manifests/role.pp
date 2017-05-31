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
    $message = $description ? {
        undef   => "${::hostname} is ${title}",
        default => "${::hostname} is a ${description} (${title})",
    }

    motd::script { "role-${title}":
        ensure   => $ensure,
        priority => 15,
        content  => "#!/bin/sh\necho '${message}'\n",
    }
}
