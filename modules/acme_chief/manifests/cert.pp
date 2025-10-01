# SPDX-License-Identifier: Apache-2.0
# deploys the especified certificate on $certs_path using the following structure:
#   $certs_path/$title:
#       live -> random_dir_name
#       new  -> random_dir_name
#       random_dir_name:
#           rsa-2048.key
#           ec-prime256v1.key
#           [rsa-2048,ec-prime256v1].[chain,chained].crt
#           [rsa-2048,ec-prime256v1].crt
#           [rsa-2048,ec-prime256v1].ocsp
define acme_chief::cert (
    Wmflib::Ensure   $ensure     = present,
    String           $key_group  = 'root',
    Optional[String] $puppet_svc = undef,
    Optional[Type]   $puppet_rsc = undef,
    Stdlib::Unixpath $certs_path = '/etc/acmecerts',
) {
    require acme_chief

    if !defined(File[$certs_path]) {
        file { $certs_path:
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
    }

    # Provide /etc/acmecerts as a symlink if $certs_path doesn't create it (see T391338)
    if $certs_path != '/etc/acmecerts' and !defined(File['/etc/acmecerts']) {
        file { '/etc/acmecerts':
            ensure  => link,
            target  => $certs_path,
            require => File[$certs_path],
        }
    }

    $acmechief_host = lookup('acmechief_host')  # lint:ignore:wmf_styleguide
    # lint:ignore:puppet_url_without_modules
    file { "${certs_path}/${title}":
        ensure    => stdlib::ensure($ensure, 'directory'),
        owner     => 'root',
        group     => $key_group,
        mode      => '0640',
        recurse   => true,
        purge     => true,
        show_diff => false,
        backup    => false,
        source    => "puppet://${acmechief_host}/acmedata/${title}",
        force     => true,
    }

    if $puppet_svc {
        File["${certs_path}/${title}"] ~> Service[$puppet_svc]
    }
    if $puppet_rsc {
        File["${certs_path}/${title}"] ~> $puppet_rsc
    }
    # lint:endignore
}
