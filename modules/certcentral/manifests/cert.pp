define certcentral::cert (
    String $puppet_svc = 'nginx',
) {
    if !defined(File['/etc/centralcerts']) {
        file { '/etc/centralcerts':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0600',
        }
    }

    @@file { "/etc/certcentral/conf.d/authorisedhost_${title}__${::fqdn}.yaml":
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => ordered_yaml({
            'hostname' => $::fqdn,
            'certname' => $title
        }),
        tag     => 'certcentral-authorisedhosts',
    }

    ['rsa-2048', 'ec-prime256v1'].each |String $type| {
        # lint:ignore:puppet_url_without_modules
        file { "/etc/centralcerts/${title}.${type}.public.pem":
            owner  => 'root',
            group  => 'root',
            mode   => '0644',
            source => "puppet://${::certcentral_host}/acmedata/${title}/${type}.crt",
        }

        file { "/etc/centralcerts/${title}.${type}.fullchain.pem":
            owner  => 'root',
            group  => 'root',
            mode   => '0644',
            source => "puppet://${::certcentral_host}/acmedata/${title}/${type}.chained.crt",
        }

        file { "/etc/centralcerts/${title}.${type}.private.pem":
            owner  => 'root',
            group  => 'root',
            mode   => '0600',
            source => "puppet://${::certcentral_host}/acmedata/${title}/${type}.key",
        }
        # lint:endignore
    }
}
