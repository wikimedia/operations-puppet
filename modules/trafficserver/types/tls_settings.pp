# Trafficserver::TLS_settings wraps the common TLS settings for incoming and outbound traffic
#
# [*outbound_tlsv1*]
#   Whether or not to enable TLSv1 for outbound TLS.
#
# [*outbound_tlsv1_1*]
#   Whether or not to enable TLSv1.1 for outbound TLS.
#
# [*outbound_tlsv1_2*]
#   Whether or not to enable TLSv1.2 for outbound TLS.
#
# [*cipher_suite*]
#   The set of encryption, digest, authentication, and key exchange algorithms
#   which Traffic Server will use for outbound TLS connections. Default to the
#   empty string, in which case the values chosen by Traffic Server for
#   proxy.config.ssl.server.cipher_suite will be used. See
#   https://docs.trafficserver.apache.org/en/8.0.x/admin-guide/files/records.config.en.html
#
# [*cipher_suite_tls_v1_3*]
#   The set of encryption, digest, authentication, and key exchange algorithms
#   which Traffic Server will use for outbound TLSv1.3 connections. Default to the
#   empty string, in which case the values chosen by Traffic Server for
#   proxy.config.ssl.server.TLSv1_3.cipher_suites will be used. See
#   https://docs.trafficserver.apache.org/en/8.0.x/admin-guide/files/records.config.en.html
#
type Trafficserver::TLS_settings = Struct[{
    'cipher_suite'          => Optional[String],
    'cipher_suite_tlsv1_3'  => Optional[String],
    'enable_tlsv1'          => Integer[0, 1],
    'enable_tlsv1_1'        => Integer[0, 1],
    'enable_tlsv1_2'        => Integer[0, 1],
    'enable_tlsv1_3'        => Integer[0, 1],
    'groups_list'           => Optional[String],
}]
