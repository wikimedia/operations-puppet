# A defined type to add agroup to sudoers file.
define sudo::group(
    $privileges = [],
    $ensure     = 'present',
    $group      = $title
) {

    file { "/etc/sudoers.d/${title}":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => template('sudo/sudoers.erb'),
    }

}
