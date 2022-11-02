# SPDX-License-Identifier: Apache-2.0
# deploys the especified certificate on /etc/acmecerts using the following structure:
#   /etc/acmecerts/$title:
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
) {
    require acme_chief

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
        ensure    => stdlib::ensure($ensure, 'directory'),
        owner     => 'root',
        group     => $key_group,
        mode      => '0640',
        recurse   => true,
        show_diff => false,
        backup    => false,
        source    => "puppet://${::acmechief_host}/acmedata/${title}",
        force     => true,
    }

    if $puppet_svc {
        File["/etc/acmecerts/${title}"] ~> Service[$puppet_svc]
    }
    if $puppet_rsc {
        File["/etc/acmecerts/${title}"] ~> $puppet_rsc
    }
    # lint:endignore
}
