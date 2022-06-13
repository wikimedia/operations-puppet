# SPDX-License-Identifier: Apache-2.0
# ATSkafka::TLS_settings allows to configure atskafka to use TLS for
# connections to the brokers for both client authentication and data
# encryption.
#
# [*ca_location*]
#   CA certificate absolute path, or simply the certificate of the entity that
#   signed and that is able to verify the client's key.
#
# [*key_location*]
#   TLS client key absolute path.
#
# [*key_password*]
#   TLS client key password.
#
# [*certificate_location*]
#   TLS client certificate absolute path.
#
# [*cipher_suites*]
#   Comma separated string of cipher suites that are permitted to be used for
#   TLS communication with brokers. This must match at least one of the cipher
#   suites allowed by the brokers.
#
# [*curves_list*]
#   Colon separated string of supported curves/named groups. This must match at
#   least one of the named groups supported by the broker. More details in
#   SSL_CTX_set1_curves_list(3).
#
# [*sigalgs_list*]
#   Colon separared string of supported signature algorithms. This must match
#   at least one of the signature algorithms supported by the broker. More
#   details in SSL_set1_client_sigalgs(3).
#
type ATSkafka::TLS_settings = Struct[{
    'ca_location'          => Stdlib::Absolutepath,
    'key_location'         => Stdlib::Absolutepath,
    'key_password'         => String,
    'certificate_location' => Stdlib::Absolutepath,
    'cipher_suites'        => String,
    'curves_list'          => String,
    'sigalgs_list'         => String,
}]
