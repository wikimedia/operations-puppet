define install_certificate {
    sslcert::certificate { $name:
        source  => "puppet:///files/ssl/${name}.crt",
        private => "puppet:///private/ssl/${name}.key",
    }
}
