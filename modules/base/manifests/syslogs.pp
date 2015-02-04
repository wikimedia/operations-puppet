class base::syslogs (
    $readable = false,
    $logfiles = [ 'syslog', 'messages' ],
    ) {

    define syslogs::readable() {

        file { "/var/log/${name}":
            mode => '0644',
        }
    }

    if $readable == true {
        syslogs::readable { $logfiles: }
    }
}