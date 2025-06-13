# SPDX-License-Identifier: Apache-2.0
class profile::metamonitoring::public_endpoint (
    String $group = lookup('profile::metamonitoring::group', {default_value => 'prometamon'}),
    Stdlib::Absolutepath $install_dir = lookup('profile::metamonitoring::install_dir', {default_value => '/usr/local/prometheus-metamonitoring'}),
    String $acme_chief_cert = lookup('profile::metamonitoring::acme_chief_cert', {default_value => 'metamonitoring'}),
    Array[String] $datacenters = lookup('datacenters', {default_value => ['dummy']}),
    Optional[String] $hostname = lookup('profile::metamonitoring::hostname', { 'default_value' => 'metamonitoring' }),
    Optional[String] $domain = lookup('profile::metamonitoring::domain', { 'default_value' => undef }),
) {
    class { 'metamonitoring::public_endpoint':
        prometheus_metamonitor_group => $group,
        install_dir                  => $install_dir,
        datacenters                  => $datacenters,
    }

    acme_chief::cert { $acme_chief_cert:
        puppet_svc => 'apache2',
    }

    $vhost_domain = $domain ? {
        undef =>  $facts['networking']['domain'],
        default => $domain
    }

    $virtual_vhost = "${hostname}.${vhost_domain}"
    httpd::site { $virtual_vhost:
        content  => epp('profile/metamonitoring/public_endpoint.conf.epp', {
                      'vhost'           => $virtual_vhost,
                      'acme_chief_cert' => $acme_chief_cert
                    }),
    }

    $physical_vhost = "${hostname}-${facts['hostname']}.${vhost_domain}"
    httpd::site { $physical_vhost:
        content  => epp('profile/metamonitoring/public_endpoint.conf.epp', {
                      'vhost'           => $physical_vhost,
                      'acme_chief_cert' => $acme_chief_cert
                    }),
    }

}
