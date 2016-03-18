# are syslogs readable or not
define base::syslogs::readable() {

    file { "/var/log/${name}":
        mode => '0644',
    }
}
