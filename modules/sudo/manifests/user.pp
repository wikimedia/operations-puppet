# A defined type for adding a user to sudoers file.
define sudo::user(
    $privileges
) {
    $user = $title

    file { "/etc/sudoers.d/${user}":
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => template('sudo/sudoers.erb'),
    }

}
