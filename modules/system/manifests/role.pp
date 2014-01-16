# Prints a MOTD message about the role of this system
define system::role($description, $ensure=present) {
    $role_script_content = "#!/bin/sh

echo \"$(hostname) is a Wikimedia ${description} (${title}).\"
"

    $rolename = regsubst($title, ':', '-', 'G')
    $motd_filename = "/etc/update-motd.d/05-role-${rolename}"
    salt::grain { $rolename: grain => 'rolename', value => $name }

    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '9.10') >= 0 {
        file { $motd_filename:
            ensure  => $ensure,
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            content => $role_script_content,
        }
    }
}
