# SPDX-License-Identifier: Apache-2.0
type Profile::Pki::Intermediate = Struct[{
    ocsp_port      => Stdlib::Port,
    profiles       => Optional[Hash[String, Cfssl::Profile]],
    auth_keys      => Optional[Hash[String, Cfssl::Auth_key]],
    nets           => Optional[Array[Stdlib::IP::Address]],
    default_usages => Optional[Array[Cfssl::Usage]],
}]
