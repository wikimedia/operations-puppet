# Describes the network probes active for the service
#
# @param [String] type
#     The probe type to deploy
# @param [Optional[String]] path
#     The URL path to use when probing the service

type Wmflib::Service::Probes = Array[
  Struct[{
    'type' => Enum['http'],
    'path' => Optional[String],
  }]
]
