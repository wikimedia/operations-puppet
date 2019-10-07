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
# [*acme_chief*]
#   Boolean signaling whether the certificate is being managed by acme-chief.
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
# [*common_name*]
#   Common name of the certificate. Only used for monitoring purposes. Not setting this parameter
#   disables the monitoring.
#
# [*sni*]
#   List of Subject Name Indication of the certificate. Only used for monitoring purposes.
#   Not setting this parameter disables the monitoring.
#
# [*warning_threshold*]
#   Warning threshold for the certificate expire date. Not setting this parameter disables the monitoring.
#
# [*critical_threshold*]
#   Critical threshold for the certificate expire date. Not setting this parameter disables the monitoring.
#
type Trafficserver::TLS_certificate = Struct[{
    'default'                  => Boolean,
    'acme_chief'               => Boolean,
    'cert_files'               => Array[String],
    'private_key_files'        => Array[String],
    'ocsp_stapling_files'      => Optional[Array[String]],
    'common_name'              => Optional[String],
    'sni'                      => Optional[Array[String]],
    'warning_threshold'        => Optional[Integer[0]],
    'critical_threshold'       => Optional[Integer[0]],
}]
