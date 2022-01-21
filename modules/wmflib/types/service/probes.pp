# Describes the network probes active for the service
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

type Wmflib::Service::Probes = Array[
  Struct[{
    'type'                => Enum['http'],
    'path'                => Optional[String],
    'host'                => Optional[String],
    'post_json'           => Optional[String],
    'must_contain_regexp' => Optional[String],
    'valid_status_codes'  => Optional[Array[Stdlib::HttpStatus]],
  }]
]
