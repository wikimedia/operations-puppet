# deploys the especified certificate on /etc/acmecerts using the following structure:
#   /etc/acmecerts/$title:
#       live -> random_dir_name
#       new  -> random_dir_name
#       random_dir_name:
#           rsa-2048.key
#           ec-prime256v1.key
#           [rsa-2048,ec-prime256v1].[chain,chained].crt
#           [rsa-2048,ec-prime256v1].crt
#           [rsa-2048,ec-prime256v1].client.ocsp --> OCSP stapling response prefetched by the client
#           [rsa-2048,ec-prime256v1].ocsp --> OCSP stapling response prefetched by acme-chief server: TBI
define acme_chief::cert (
    $ensure = present,
    Variant[String, Undef] $puppet_svc = undef,
    String $key_group = 'root',
    Boolean $ocsp = false,
    Variant[String, Undef] $ocsp_proxy = undef,
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
        ensure    => ensure_directory($ensure),
        owner     => 'root',
        group     => $key_group,
        mode      => '0640',
        recurse   => true,
        show_diff => false,
        source    => "puppet://${::acmechief_host}/acmedata/${title}",
        notify    => Service[$puppet_svc],
    }
    # lint:endignore

    if $ocsp {
        # This will dissapear as soon as acme-chief performs OCSP stapling centrally
        require sslcert::ocsp::init # lint:ignore:wmf_styleguide

        ['ec-prime256v1', 'rsa-2048'].each |String $type| {
            ['live', 'new'].each |String $version| {
                $config = "/etc/update-ocsp.d/${title}-${version}-${type}.conf"
                $output = "/etc/acmecerts/${title}/${version}/${type}.client.ocsp"
                $cert_path = "/etc/acmecerts/${title}/${version}/${type}.crt"
                file { $config:
                    ensure  => $ensure,
                    owner   => 'root',
                    group   => 'root',
                    mode    => '0444',
                    content => template('acme_chief/update-ocsp.erb'),
                    require => File["/etc/acmecerts/${title}"],
                }

                if $ensure == 'present' {
                    # initial creation on the first puppet run
                    exec { "${title}-${version}-${type}-create-ocsp":
                        command => "/usr/local/sbin/update-ocsp --config ${config}",
                        creates => $output,
                        require => File[$config],
                    }
                } else {
                    file { $output:
                        ensure => absent,
                    }
                }
            }
        }
    }
}
