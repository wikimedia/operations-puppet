# SPDX-License-Identifier: Apache-2.0
type Apereo_cas::Delegate::Cas = Struct[{
    provider      => Enum['cas'],
    login_url     => Stdlib::HTTPSUrl,
    protocol      => Enum['CAS20', 'CAS30'],
    client_name   => Optional[String[1]],
    display_name  => Optional[String[1]],
    auto_redirect => Optional[Boolean],
}]
