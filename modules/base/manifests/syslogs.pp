# handle syslog permissions (e.g. 'make common logs readable by normal users (T80830)')
class base::syslogs (
    $readable = false,
    $logfiles = [ 'syslog', 'messages' ],
    ) {

    if $readable == true {
        syslogs::readable { $logfiles: }
    }
}
