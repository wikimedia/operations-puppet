define authdns::zonefile($destdir) {
    $zonename = $title # convenience for templating
    file { "${destdir}/${title}":
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("${module_name}/zones/${title}"),
    }
}
