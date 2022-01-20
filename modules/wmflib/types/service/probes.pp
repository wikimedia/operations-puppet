# Describes the network probes active for the service
#
# @param [String] type
#     The probe type to deploy
# @param [Optional[String]] path
#     The URL path to use when probing the service
# @param [Optional[String]] host
#     The Host header to send
# @param [Optional[String]] post_json
#     POST the given JSON string
# @param [Optional[String]] must_contain_regexp
#     Search the response's body for this regular expression

type Wmflib::Service::Probes = Array[
  Struct[{
    'type'                => Enum['http'],
    'path'                => Optional[String],
    'host'                => Optional[String],
    'post_json'           => Optional[String],
    'must_contain_regexp' => Optional[String],
  }]
]
