# Trafficserver::Negative_Caching is the data type representing the settings
# used to configure Negative Response Caching.
# See https://docs.trafficserver.apache.org/en/8.0.x/admin-guide/files/records.config.en.html#negative-response-caching
#
# [*status_codes*]
#   Array of HTTP status codes for which negative caching should be enabled.
#
# [*lifetime*]
#   TTL, in seconds, to be applied to negative responses without Cache-Control
#   or Expires.

type Trafficserver::Negative_Caching = Struct[{
    'status_codes' => Array[Wmflib::HttpStatus],
    'lifetime'     => Integer,
}]
