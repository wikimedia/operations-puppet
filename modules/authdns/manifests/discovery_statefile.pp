
define authdns::discovery_statefile($lvs, $lvs_services, $active_active) {
    $check = $active_active ? {
        false => '/usr/local/bin/authdns-check-active-passive',
        true  => undef,
    }

    $keyspace = '/discovery'

    confd::file { "/var/lib/gdnsd/discovery-${title}.state":
        uid        => '0',
        gid        => '0',
        mode       => '0444',
        content    => template("${module_name}/discovery-statefile.tpl.erb"),
        watch_keys => ["${keyspace}/${title}"],
        check      => $check,
    }
}
