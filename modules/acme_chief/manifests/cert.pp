# deploys the especified certificate on /etc/acmecerts using the following structure:
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
    $ensure = present,
    Optional[String] $puppet_svc = undef,
    Optional[Type] $puppet_rsc = undef,
    String $key_group = 'root',
    Optional[Boolean] $ocsp = undef, # deprecated, it will be removed soon
    Optional[String] $ocsp_proxy = undef, # deprecated, it will be removed soon
) {
    require ::acme_chief

    if defined('$ocsp') {
        warning('ocsp parameter will be removed soon')
    }
    if $ocsp_proxy {
        warning('ocsp_proxy parameter will be removed soon')
    }

    if !defined(File['/etc/acmecerts']) {
        file { '/etc/acmecerts':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
    }

    $notify_svc = $puppet_svc? {
        undef   => [],
        default => [Service[$puppet_svc]],
    }
    $notify_rsc = $puppet_rsc? {
        undef   => $notify_svc,
        default => concat($notify_svc, [$puppet_rsc])
    }

    if !empty($notify_rsc) {
        $notify = $notify_rsc
    } else {
        $notify = undef
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
        notify    => $notify,
    }
    # lint:endignore
}
