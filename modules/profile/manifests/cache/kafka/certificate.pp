# == Class profile::cache::kafka::certs
# Installs certificates and keys for varnishkafka to produce to Kafka over TLS.
# This expects that a 'varnishkafka' SSL/TLS key and certificate is created by Cergen and
# signed by our PuppetCA, and available in the Puppet private secrets module.
# == Parameters.
#
# [*ssl_key_password*]
#   The password to decrypt the TLS client certificate.  Default: undef
#
# [*certificate_name*]
#   Name of certificate (cergen) in the secrets module.  This will be used
#   To find the certificate file secret() puppet paths.
#
# [*certificate_name*]
#   Name of certificate (cergen) in the secrets module.  This will be used
#   To find the certificate file secret() puppet paths.  You might want to
#   change this if you are testing in Cloud VPS.  Default: varnishkafka.
#
# [*use_puppet_internal_ca*]
#   If true, the CA cert.pem file will be assumed to be already installed at
#   /etc/ssl/certs/Puppet_Internal_CA.pem, and will be used as the ssl.ca.location
#   for varnishkafka/librdkafka.  Default: true.  Set this to false if the
#   certificate name you set is not signed by the Puppet CA, and the
#   cergen created ca.crt.pem file will be used.
#
class profile::cache::kafka::certificate(
    $ssl_key_password  = hiera('profile::cache::kafka::certificate::ssl_key_password', undef),
    $certificate_name = hiera('profile::cache::kafka::certificate::certificate_name', 'varnishkafka'),
    $use_puppet_internal_ca = hiera('profile::cache::kafka::certificate::use_puppet_internal_ca', true),
) {
    # TLS/SSL configuration
    $ssl_location = '/etc/varnishkafka/ssl'
    $ssl_location_private = '/etc/varnishkafka/ssl/private'

    $ssl_key_location_secrets_path = "certificates/${certificate_name}/${certificate_name}.key.private.pem"
    $ssl_key_location = "${ssl_location_private}/${certificate_name}.key.pem"

    $ssl_certificate_secrets_path = "certificates/${certificate_name}/${certificate_name}.crt.pem"
    $ssl_certificate_location = "${ssl_location}/${certificate_name}.crt.pem"
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

    if $use_puppet_internal_ca {
        $ssl_ca_location = '/etc/ssl/certs/Puppet_Internal_CA.pem'
    }
    else {
        $ssl_ca_location_secrets_path = "certificates/${certificate_name}/ca.crt.pem"
        $ssl_ca_location = "${ssl_location}/ca.crt.pem"

        file { $ssl_ca_location:
            content => secret($ssl_ca_location_secrets_path),
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
        }
    }
}
