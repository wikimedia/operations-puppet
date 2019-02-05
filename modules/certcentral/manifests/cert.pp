define certcentral::cert (
    Variant[String, Undef] $puppet_svc = undef,
    String $key_group = 'root',
) {
    require ::certcentral

    if !defined(File['/etc/centralcerts']) {
        file { '/etc/centralcerts':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
    }

    ['rsa-2048', 'ec-prime256v1'].each |String $type| {
        # lint:ignore:puppet_url_without_modules
        file { "/etc/centralcerts/${title}.${type}.crt":
            owner  => 'root',
            group  => 'root',
            mode   => '0644',
            source => "puppet://${::certcentral_host}/acmedata/${title}/${type}.crt",
            notify => Service[$puppet_svc],
        }

        file { "/etc/centralcerts/${title}.${type}.chain.crt":
            owner  => 'root',
            group  => 'root',
            mode   => '0644',
            source => "puppet://${::certcentral_host}/acmedata/${title}/${type}.chain.crt",
            notify => Service[$puppet_svc],
        }

        file { "/etc/centralcerts/${title}.${type}.chained.crt":
            owner  => 'root',
            group  => 'root',
            mode   => '0644',
            source => "puppet://${::certcentral_host}/acmedata/${title}/${type}.chained.crt",
            notify => Service[$puppet_svc],
        }

        file { "/etc/centralcerts/${title}.${type}.key":
            owner  => 'root',
            group  => $key_group,
            mode   => '0640',
            source => "puppet://${::certcentral_host}/acmedata/${title}/${type}.key",
            notify => Service[$puppet_svc],
        }
        # lint:endignore
    }
}
