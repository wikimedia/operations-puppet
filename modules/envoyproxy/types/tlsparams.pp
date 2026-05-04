# SPDX-License-Identifier: Apache-2.0
type Envoyproxy::Tlsparams = Struct[{
    'cipher_suites' => Optional[Array[String]],
    'ecdh_curves'   => Optional[Array[String]],
}]
