# SPDX-License-Identifier: Apache-2.0
# @summary configure cfssl multirootca
# @param ensure whether to ensure this class
# @param host the host address to listen on
# @param port the port to listen on
# @param enable_monitoring indicate if we should configure monitoring for the service
# @param monitoring_critical indicate if monitoring should page
# @param signers a hash of signer configs
# @param tls_cert path to the tls public cert used for client auth if any
# @param tls_key path to the tls private key used for client auth if any
class cfssl::multirootca (
    Wmflib::Ensure                  $ensure              = 'present',
    Stdlib::Host                    $host                = '127.0.0.1',
    Stdlib::Port                    $port                = 8888,
    Boolean                         $enable_monitoring   = false,
    Boolean                         $monitoring_critical = false,
    Hash[String, Cfssl::CA::Config] $signers             = {},
    Optional[Stdlib::Unixpath]      $tls_cert            = undef,
    Optional[Stdlib::Unixpath]      $tls_key             = undef,
) {
    include cfssl
    $config_file = "${cfssl::conf_dir}/multiroot.conf"
    $service_name = 'cfssl-multirootca'
    file {$config_file:
        ensure  => $ensure,
        content => template('cfssl/multiroot.conf.erb'),
        notify  => Service[$service_name],
    }
    file {'/usr/local/sbin/cfssl-certs':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0500',
        source => 'puppet:///modules/cfssl/cfssl_certs.py',
    }
    systemd::service {'cfssl-multirootca':
        monitoring_enabled   => $enable_monitoring,
        monitoring_critical  => $monitoring_critical,
        monitoring_notes_url => 'https://wikitech.wikimedia.org/wiki/PKI',
        content              => template('cfssl/cfssl-multirootca.service.erb'),
        restart              => true,
    }
}
