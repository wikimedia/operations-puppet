# SPDX-License-Identifier: Apache-2.0
type Sslcert::Trusted_certs = Struct[{
    certs   => Array[Stdlib::Unixpath],
    bundle  => Stdlib::Unixpath,
    package => Optional[String]
}]
