## SPDX-License-Identifier: Apache-2.0
# Trafficserver::Outbound_TLS_settings wraps the specific settings for outbound TLS traffic
#
# [*verify_origin*]
#   If true, validate origin server certificate.
#
# [*verify_server_policy*]
#   ATS 9.x:
#   The policy (PERMISSIVE, ENFORCED) under which the origin server certificate
#   is verified or not (DISABLED).
#
# [*cacert_dirpath*]
#   If specified, absolute path to the directory containing the certificates
#   that will be used for origin server certificate validation.
#
# [*cacert_filename*]
#   If specified, absolute path of the filename of the CA to trust for
#   origin server certificate validation.

type Trafficserver::Outbound_TLS_settings = Struct[{
    'common'               => Trafficserver::TLS_settings,
    'verify_origin'        => Boolean,
    'verify_server_policy' => Optional[Enum['DISABLED', 'PERMISSIVE', 'ENFORCED']],
    'cacert_dirpath'       => Optional[Stdlib::Absolutepath],
    # TODO: Replace String with Stdlib::Absolutepath after updating
    # the config cluster wide.
    'cacert_filename'      => Optional[String],
}]
