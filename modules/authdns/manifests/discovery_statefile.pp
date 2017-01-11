
define authdns::discovery_statefile($lvs_services) {
    file { "/etc/confd.d/templates/${title}":
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("${module_name}/discovery-statefile.tpl.erb"),
        require => File['/etc/gdnsd'],
        notify  => Service['gdnsd'],
    }
}
