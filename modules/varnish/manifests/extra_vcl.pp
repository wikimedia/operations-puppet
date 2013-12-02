define varnish::extra_vcl {
    $vcl = regsubst($title, '^([^ ]+) .*$', '\1')
    $filename = "/etc/varnish/${vcl}.inc.vcl"

    if !defined(File[$filename]) {
        file { $filename:
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template("varnish/${vcl}.inc.vcl.erb"),
        }
    }
}
