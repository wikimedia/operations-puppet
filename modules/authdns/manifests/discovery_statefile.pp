
define authdns::discovery_statefile($lvs_services) {
    confd::file { "/var/lib/gdnsd/discovery-${title}.state":
        uid        => '0',
        gid        => '0',
        mode       => '0444',
        content    => template("${module_name}/discovery-statefile.tpl.erb"),
        watch_keys => "/discovery/${title}",
    }
}
