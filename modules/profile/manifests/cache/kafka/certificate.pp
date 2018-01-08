# == Class profile::cache::kafka::certs
# Installs certificates and keys for varnishkafka to produce to Kafka over TLS.
# This expects that a 'varnishkafka' SSL/TLS key and certificate is created by Cergen and
# signed by our PuppetCA, and available in the Puppet private secrets module.
# == Parameters.
# [*ssl_key_password*]
#   The password to decrypt the TLS client certificate.  Default: undef
#
class profile::cache::kafka::certificate(
    $ssl_key_password  = hiera('profile::cache::kafka::certificate::ssl_key_password', undef),
) {
    # TLS/SSL configuration
    $ssl_ca_location = '/etc/ssl/certs/Puppet_Internal_CA.pem'
    $ssl_location = '/etc/varnishkafka/ssl'
    $ssl_location_private = '/etc/varnishkafka/ssl/private'

    $ssl_key_location_secrets_path = 'certificates/varnishkafka/varnishkafka.key.private.pem'
    $ssl_key_location = "${ssl_location_private}/varnishkafka.key.pem"

    $ssl_certificate_secrets_path = 'certificates/varnishkafka/varnishkafka.crt.pem'
    $ssl_certificate_location = "${ssl_location}/varnishkafka.crt.pem"
    $ssl_cipher_suites = 'ECDHE-ECDSA-AES256-GCM-SHA384'

    file { $ssl_location:
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { $ssl_location_private:
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0500',
        require => File[$ssl_location],
    }

    file { $ssl_key_location:
        content => secret($ssl_key_location_secrets_path),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => File[$ssl_location_private],
    }

    file { $ssl_certificate_location:
        content => secret($ssl_certificate_secrets_path),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
