define varnish::extra_vcl {
    $vcl = regsubst($title, '^([^ ]+) .*$', '\1')
    $filename = "/etc/varnish/${vcl}.inc.vcl"

    if !defined(File[$filename]) {
        file { $filename:
            content => template("varnish/${vcl}.inc.vcl.erb"),
            mode    => '0444',
        }
    }
}
