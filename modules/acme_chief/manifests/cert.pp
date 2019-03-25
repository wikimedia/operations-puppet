# deploys the especified certificate on /etc/acmecerts using the following structure:
#   /etc/acmecerts/$title:
#       live -> random_dir_name
#       new  -> random_dir_name
#       random_dir_name:
#           rsa-2048.key
#           ec-prime256v1.key
#           [rsa-2048,ec-prime256v1].[chain,chained].crt
#           [rsa-2048,ec-prime256v1].crt
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
