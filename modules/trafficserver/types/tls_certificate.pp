# Trafficserver::Inbound_TLS_settings wraps the specific settings
# for one or more certificates with the same SNI list
# This gets translated in one single line of ssl_multicert.config
# Valid example: 'dst_ip=* ssl_cert_name=unified.chained.crt ssl_key_name=unified.key'
# Check https://docs.trafficserver.apache.org/en/8.0.x/admin-guide/files/ssl_multicert.config.en.html
# for more details
#
# [*default*]
#   Sets the default certificate to be used when SNI doesn't match any existing certificate
#
# [*cert_files*]
#   Array containing the file names of the SSL certificates.
#
# [*private_key_files*]
#   Array containing the file names of the SSL certificate private keys.
#
# [*ocsp_stapling_files*]
#   Array containing the file names of the OCSP stapling responses. Not setting this parameter will result in
#   OCSP stapling being disabled.
#
type Trafficserver::TLS_certificate = Struct[{
    'default'                  => Boolean,
    'cert_files'               => Array[String],
    'private_key_files'        => Array[String],
    'ocsp_stapling_files'      => Optional[Array[String]],
}]
