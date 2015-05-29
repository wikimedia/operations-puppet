define install_certificate(
    $group     = 'ssl-cert',
    $privatekey=true,
) {
    sslcert::certificate { $name:
        group  => $group,
        source => "puppet:///files/ssl/${name}.crt",
    }

    if ( $privatekey == true ) {
        Sslcert::Certificate[$name] {
            private => "puppet:///private/ssl/${name}.key",
        }
    }
}
