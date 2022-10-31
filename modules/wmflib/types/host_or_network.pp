# SPDX-License-Identifier: Apache-2.0
# Stdlib::Host uses Stdlib::Compat::Ip_address which doesn't include networks
type Wmflib::Host_or_network = Variant[Stdlib::Fqdn, Stdlib::IP::Address]
