define authdns::template($destdir) {
    file { "${destdir}/${title}":
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("${module_name}/${title}.erb"),
    }
}
