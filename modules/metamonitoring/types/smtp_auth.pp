# SPDX-License-Identifier: Apache-2.0
type Metamonitoring::Smtp_auth = Struct[{
    host      => Stdlib::Fqdn,
    port      => Stdlib::Port,
    username  => Stdlib::Email,
    password  => String[2],
    mail_from => Stdlib::Email,
}]

