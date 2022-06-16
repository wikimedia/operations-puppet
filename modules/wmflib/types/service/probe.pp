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
#     Defaults to '3s' unless overridden. The maximum value is set by Prometheus'
#     scrape_timeout, which in turn cannot be higher than scrape_interval.
#     (15s for service::catalog probes)

type Wmflib::Service::Probe = Struct[{
    'type'                  => Enum['http', 'tcp', 'tcp-notls'],
    'path'                  => Optional[String[1]],
    'host'                  => Optional[String[1]],
    'post_json'             => Optional[String[1]],
    'must_contain_regexp'   => Optional[String[1]],
    'valid_status_codes'    => Optional[Array[Stdlib::HttpStatus]],
    'expect_sso'            => Optional[Boolean],
    'expect_redirect'       => Optional[Boolean],
    'timeout'               => Optional[String[1]],
}]
