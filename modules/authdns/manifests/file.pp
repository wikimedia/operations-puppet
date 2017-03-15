define authdns::file($destdir) {
    file { "${destdir}/${title}":
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => "puppet:///modules/${module_name}/${title}",
    }
}
