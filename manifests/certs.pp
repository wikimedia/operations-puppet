define install_certificate(
    $privatekey=true,
) {
    sslcert::certificate { $name:
        source => "puppet:///files/ssl/${name}.crt",
    }

    if ( $privatekey == true ) {
        Sslcert::Certificate[$name] {
            private => "puppet:///private/ssl/${name}.key",
        }
    }
}
