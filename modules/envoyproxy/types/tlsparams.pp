# SPDX-License-Identifier: Apache-2.0
type Envoyproxy::Tlsparams = Struct[{
    'cipher_suites'   => Optional[Array[String]],
    'ecdh_curves'     => Optional[Array[String]],
    'tls_min_version' => Optional[Enum['TLSv1_0', 'TLSv1_1', 'TLSv1_2', 'TLSv1_3']],
    'tls_max_version' => Optional[Enum['TLSv1_0', 'TLSv1_1', 'TLSv1_2', 'TLSv1_3']],
}]
