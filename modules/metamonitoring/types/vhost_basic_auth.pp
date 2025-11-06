# SPDX-License-Identifier: Apache-2.0
type Metamonitoring::Vhost_basic_auth = Struct[{
    domain   => Stdlib::Fqdn,
    username => String[2],
    password => String[2],
}]
