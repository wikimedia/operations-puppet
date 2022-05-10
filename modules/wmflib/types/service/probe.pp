# Describes a service network probe
#
# @param [String] type
#     The probe type to deploy
# @param [Optional[String]] path
#     The URL path to use when probing the service
# @param [Optional[String]] host
#     The Host header to send. Overrides SNI too.
# @param [Optional[String]] post_json
#     POST the given JSON string
# @param [Optional[String]] must_contain_regexp
#     Search the response's body for this regular expression
# @param [Optional[Array[Stdlib::HttpStatus]]] valid_status_codes
#     Accept these HTTP statuses as valid (default 200-299)
# @param [Optional[Boolean] expect_sso
#     Expect a SSO login from the endpoint (default false)
# @param [Optional[Integer] timeout
#     How long the probe will wait before giving up (in golang duration format).
#     This value is set by Prometheus' job configuration via 'scrape_timeout' and defaults to 10s.
#     It can be overridden here.

type Wmflib::Service::Probe = Struct[{
    'type'                  => Enum['http', 'tcp', 'tcp-notls'],
    'path'                  => Optional[String],
    'host'                  => Optional[String],
    'post_json'             => Optional[String],
    'must_contain_regexp'   => Optional[String],
    'valid_status_codes'    => Optional[Array[Stdlib::HttpStatus]],
    'expect_sso'            => Optional[Boolean],
    'expect_redirect'       => Optional[Boolean],
    'timeout'               => Optional[String],
}]
