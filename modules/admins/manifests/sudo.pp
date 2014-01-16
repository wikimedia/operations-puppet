define admins::sudo(
    $privileges=[],
    $ensure='present',
) {

    $lhs = $title
    $filename = $title ? {
        /^%(.*)/ => "group-${1}",
        default  => $0,
    }

    file { "/etc/sudoers.d/${filename}":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => template("${module_name}/sudo/sudoers.erb"),
    }
}
