# handle syslog permissions (e.g. 'make common logs readable by normal users (RT-2712)')
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