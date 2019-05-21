# Trafficserver::Inbound_TLS_settings wraps the specific settings for inbound TLS traffic
#
# [*cert_path*]
#   The location of the SSL certificates and chains used for accepting and validaating new SSL sessions.
#
# [*private_key_path*]
#   The location of the SSL certificate private keys.
#
# [*ocsp_stapling_path*]
#   The location of the prefetched OCSP stapling responses. Not setting this parameter will result in OCSP stapling
#   being disabled.
#
# [*dhparams_file*]
#   The name of a file containing a set of Diffie-Hellman key exchange parameters.
#   If not specified, 2048-bit DH parameters from RFC 5114 are used. These parameters are only used
#   if a DHE (or EDH) cipher suite has been selected.
#
# [*max_record_size*]
#   This configuration specifies the maximum number of bytes to write into a SSL record when
#   replying over a SSL session.
#   This setting can have a value between 0 and 16383 (max TLS record size)
#   Special Values:
#      -1: TLS record size is dynamically determined.
#       0: always write all available data into a single SSL record
#   Check https://docs.trafficserver.apache.org/en/8.0.x/admin-guide/files/records.config.en.html#proxy-config-ssl-max-record-size
#   for more details
# [*session_cache*]
#   Enables the SSL session cache:
#   Values:
#       0: Disables the SSL session cache entirely
#       1: Enables the session cache using OpenSSL’s implementation
#       2: Enables the session cache using Traffic Server’s implementation.
#          This implentation should perform much better than the OpenSSL implementation.
#
# [*session_cache_timeout*]
#   Set the lifetime of SSL session cache entries in seconds.
#   If it is 0, then the SSL library will use a default value, typically 300 seconds.
#   Note: This option has no affect when using the Traffic Server session cache
#   (option 2 in session_cache)
#
# [*session_cache_auto_clear*]
#   Enable (1) or disable (0) the OpenSSL auto clear flag.
#   See https://www.openssl.org/docs/man1.1.0/man3/SSL_CTX_set_session_cache_mode.html
#
# [*session_cache_size*]
#   Set the maximum number of entries the SSL session cache may contain
#
# [*session_cache_buckets*]
#   This configuration specifies the number of buckets to use with the Traffic Server SSL session cache implementation.
#   The TS implementation is a fixed size hash map where each bucket is protected by a mutex.
#
# [*load_elevated*]
#   Enables (1) or disables (0) elevation of traffic_server privileges during loading of SSL certificates.

type Trafficserver::Inbound_TLS_settings = Struct[{
    'common'                   => Trafficserver::TLS_settings,
    'cert_path'                => Stdlib::Absolutepath,
    'private_key_path'         => Stdlib::Absolutepath,
    'ocsp_stapling_path'       => Optional[Stdlib::Absolutepath],
    'certificates'             => Array[Trafficserver::TLS_certificate],
    'dhparams_file'            => Optional[Stdlib::Absolutepath],
    'max_record_size'          => Integer[-1, 16383],
    'session_cache'            => Integer[0, 2],
    'session_cache_timeout'    => Optional[Integer[0]],
    'session_cache_auto_clear' => Integer[0, 1],
    'session_cache_size'       => Integer[0],
    'session_cache_buckets'    => Integer[0],
    'load_elevated'            => Optional[Integer[0, 1]],
}]
