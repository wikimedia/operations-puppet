# deploys the especified certificate on /etc/acmecerts
# It currently deploys the certs using two file naming schemas:
# files based:
#   /etc/acmecerts/${title}.rsa-2048.key
#   /etc/acmecerts/${title}.ec-prime256v1.key
#   /etc/acmecerts/${title}.[rsa-2048,ec-prime256v1].[chain,chained].crt
#   /etc/acmecerts/${title}.[rsa-2048,ec-prime256v1].crt
# directory based:
#   /etc/acmecerts/$title:
#       live -> random_dir_name
#       new  -> random_dir_name
#       random_dir_name:
#           rsa-2048.key
#           ec-prime256v1.key
#           [rsa-2048,ec-prime256v1].[chain,chained].crt
#           [rsa-2048,ec-prime256v1].crt
# THIS is temporary, and in the long-term only the directory based will be kept
define acme_chief::cert (
    Variant[String, Undef] $puppet_svc = undef,
    String $key_group = 'root',
) {
    require ::acme_chief

    if !defined(File['/etc/acmecerts']) {
        file { '/etc/acmecerts':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
    }

    # lint:ignore:puppet_url_without_modules
    ['rsa-2048', 'ec-prime256v1'].each |String $type| {

        file { "/etc/acmecerts/${title}.${type}.crt":
            owner  => 'root',
            group  => 'root',
            mode   => '0644',
            source => "puppet://${::acmechief_host}/acmedata/${title}/${type}.crt",
            notify => Service[$puppet_svc],
        }

        file { "/etc/acmecerts/${title}.${type}.chain.crt":
            owner  => 'root',
            group  => 'root',
            mode   => '0644',
            source => "puppet://${::acmechief_host}/acmedata/${title}/${type}.chain.crt",
            notify => Service[$puppet_svc],
        }

        file { "/etc/acmecerts/${title}.${type}.chained.crt":
            owner  => 'root',
            group  => 'root',
            mode   => '0644',
            source => "puppet://${::acmechief_host}/acmedata/${title}/${type}.chained.crt",
            notify => Service[$puppet_svc],
        }

        file { "/etc/acmecerts/${title}.${type}.key":
            owner     => 'root',
            group     => $key_group,
            mode      => '0640',
            show_diff => false,
            source    => "puppet://${::acmechief_host}/acmedata/${title}/${type}.key",
            notify    => Service[$puppet_svc],
        }
    }
    file { "/etc/acmecerts/${title}":
        ensure    => directory,
        owner     => 'root',
        group     => $key_group,
        mode      => '0640',
        recurse   => true,
        show_diff => false,
        source    => "puppet://${::acmechief_host}/acmedata/${title}",
        notify    => Service[$puppet_svc],
    }
    # lint:endignore
}
