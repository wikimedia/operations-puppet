define install_certificate(
    $group     = 'ssl-cert',
    $privatekey=true,
) {

    require base::certificates

    sslcert::certificate { $name:
        group  => $group,
        source => "puppet:///files/ssl/${name}.crt",
    }

    if ( $privatekey == true ) {
        Sslcert::Certificate[$name] {
            # private => file("puppet:///private/ssl/${name}.key"), # cf this commit in certificate.pp
            private => "puppet:///private/ssl/${name}.key",
        }
    }
}
