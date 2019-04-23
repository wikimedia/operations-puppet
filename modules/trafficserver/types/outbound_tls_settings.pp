# Trafficserver::Outbound_TLS_settings wraps the specific settings for outbound TLS traffic
#
# [*verify_origin*]
#   If true, validate origin server certificate.
#
# [*cacert_dirpath*]
#   Absolute path to the directory containing the file specified in
#   cacert_filename.
#
# [*cacert_filename*]
#   If specified, the filename of the CA to trust for origin server certificate
#   validation.

type Trafficserver::Outbound_TLS_settings = Struct[{
    'common'          => Trafficserver::TLS_settings,
    'verify_origin'   => Boolean,
    'cacert_dirpath'  => Stdlib::Absolutepath,
    'cacert_filename' => Optional[String],
}]
