# SPDX-License-Identifier: Apache-2.0
class profile::metamonitoring::public_endpoint (
    String               $group,
    Stdlib::Absolutepath $install_dir,
    Array[String]        $datacenters     = lookup('datacenters', {default_value => ['dummy']}),
    String               $acme_chief_cert = lookup('profile::metamonitoring::public_endpoint:acme_chief_cert', {default_value => 'metamonitoring'}),
    Stdlib::Host         $listen_address  = lookup('profile::metamonitoring::public_endpoint:listen_address', { default_value => '0.0.0.0' }),
    Stdlib::Port         $listen_port     = lookup('profile::metamonitoring::public_endpoint:listen_port', { default_value => 20999}),
    String               $user            = lookup('profile::metamonitoring::public_endpoint:user', { default_value => 'metamonpubep'}),
    Optional[String]     $hostname        = lookup('profile::metamonitoring::public_endpoint:hostname', { 'default_value' => 'metamonitoring' }),
    Optional[String]     $domain          = lookup('profile::metamonitoring::public_endpoint:domain', { 'default_value' => undef }),
) {

    class { 'metamonitoring::public_endpoint':
        group          => $group,
        install_dir    => $install_dir,
        datacenters    => $datacenters,
        user           => $user,
        listen_address => $listen_address,
        listen_port    => $listen_port,
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
