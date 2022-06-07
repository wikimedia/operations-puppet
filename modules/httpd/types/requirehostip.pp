# SPDX-License-Identifier: Apache-2.0
# Used in 'Require host/ip' statements, accepts hostname + ip address + ip subnet
type Httpd::RequireHostIP = Variant[Stdlib::Fqdn, Stdlib::IP::Address]
