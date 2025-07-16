# SPDX-License-Identifier: Apache-2.0
class profile::metamonitoring::public_endpoint (
    Wmflib::Ensure       $ensure          = lookup('profile::metamonitoring::ensure', {default_value => 'present'}),
    String               $group           = lookup('profile::metamonitoring::group', {default_value => 'prometamon'}),
    String               $status_dir      = lookup('profile::metamonitoring::status_dir', {default_value => '/var/lib/o11y-metamonitoring'}),
    Stdlib::Host         $active_host     = lookup('profile::alertmanager::active_host'),
    Array[String]        $datacenters     = lookup('datacenters'),
    String               $public_domain   = lookup('public_domain'),
    String               $acme_chief_cert = lookup('profile::metamonitoring::public_endpoint::acme_chief_cert', {default_value => 'metamonitoring'}),
    Stdlib::Host         $listen_address  = lookup('profile::metamonitoring::public_endpoint::listen_address', { default_value => '0.0.0.0' }),
    Stdlib::Port         $listen_port     = lookup('profile::metamonitoring::public_endpoint::listen_port', { default_value => 20999}),
    Optional[String]     $hostname        = lookup('profile::metamonitoring::public_endpoint::hostname', { 'default_value' => 'metamonitoring' }),
) {

    class { 'metamonitoring::public_endpoint':
        ensure         => $ensure,
        group          => $group,
        status_dir     => $status_dir,
        datacenters    => $datacenters,
        listen_address => $listen_address,
        listen_port    => $listen_port,
    }

    acme_chief::cert { $acme_chief_cert:
        ensure     => $ensure,
        puppet_svc => 'apache2',
    }

    $virtual_vhost = "${hostname}.${public_domain}"
    httpd::site { $virtual_vhost:
        ensure  => $ensure,
        content => epp('profile/metamonitoring/public_endpoint.conf.epp', {
                      'sname'           => $virtual_vhost,
                      'saliases'        => ["${hostname}-active.${public_domain}", "${hostname}-passive.${public_domain}"],
                      'acme_chief_cert' => $acme_chief_cert
                    }),
    }

}
