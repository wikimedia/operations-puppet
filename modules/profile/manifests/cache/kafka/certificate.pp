# SPDX-License-Identifier: Apache-2.0
# == Class profile::cache::kafka::certificate
# Installs certificates and keys for varnishkafka to produce to Kafka over TLS.
# This expects that a 'varnishkafka' SSL/TLS key and certificate are created
# by cfssl.
#
# == Parameters.
#
# [*ssl_key_password*]
#   The password to decrypt the TLS client certificate.  Default: undef
#
# [*certificate_name*]
#   Name of certificate as requested by cfssl. Default: varnishkafka
class profile::cache::kafka::certificate(
    Optional[String] $ssl_key_pass = lookup('profile::cache::kafka::certificate::ssl_key_password', {'default_value' => undef}),
    String $certificate_name           = lookup('profile::cache::kafka::certificate::certificate_name', {'default_value' => 'varnishkafka'}),
    String $ssl_cipher_suites          = lookup('profile::cache::kafka::certificate::ssl_cipher_suites', {'default_value' => 'ECDHE-ECDSA-AES256-GCM-SHA384'}),
    String $ssl_curves_list            = lookup('profile::cache::kafka::certificate::ssl_curves_list', {'default_value' => 'P-256'}),
    String $ssl_sigalgs_list           = lookup('profile::cache::kafka::certificate::ssl_sigalgs_list', {'default_value' => 'ECDSA+SHA256'}),
){
    # TLS/SSL configuration
    $ssl_location = '/etc/varnishkafka/ssl'

    $ssl_files = profile::pki::get_cert('kafka', $certificate_name, {
        'outdir'  => $ssl_location,
        'owner'   => 'root',
        'group'   => 'root',
        'profile' => 'kafka_11',
        notify    => Service['varnishkafka-all'],
    })

    $ssl_key_location = $ssl_files['key']
    $ssl_certificate_location = $ssl_files['chained']
    $ssl_key_password = $ssl_key_pass
    $ssl_ca_location = profile::base::certificates::get_trusted_ca_path()
}
