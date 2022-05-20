## SPDX-License-Identifier: Apache-2.0
# Trafficserver::Outbound_TLS_settings wraps the specific settings for outbound TLS traffic
#
# [*verify_origin*]
#   If true, validate origin server certificate.
#
# [*cacert_dirpath*]
#   If specified, absolute path to the directory containing the certificates
#   that will be used for origin server certificate validation.
#
# [*cacert_filename*]
#   If specified, absolute path of the filename of the CA to trust for
#   origin server certificate validation.

type Trafficserver::Outbound_TLS_settings = Struct[{
    'common'          => Trafficserver::TLS_settings,
    'verify_origin'   => Boolean,
    'cacert_dirpath'  => Optional[Stdlib::Absolutepath],
    # TODO: Replace String with Stdlib::Absolutepath after updating
    # the config cluster wide.
    'cacert_filename' => Optional[String],
}]
