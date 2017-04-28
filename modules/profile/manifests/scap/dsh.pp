# == Class profile::scap::dsh
#
# Installs the dsh files used by scap on a host
class profile::scap::dsh(
    $groups = hiera('scap::dsh::groups'),
    $proxies = hiera('scap::dsh::scap_proxies', []),
    $masters = hiera('scap::dsh::scap_masters', []),
    $conftool_prefix = hiera('conftool_prefix'),
) {
    class { 'confd':
        interval => 300,
        prefix   => $conftool_prefix,
    }

    class { '::scap::dsh':
        groups       => $groups,
        scap_proxies => $proxies,
        scap_masters => $masters,
    }
}
