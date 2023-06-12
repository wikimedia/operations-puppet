# SPDX-License-Identifier: Apache-2.0
# More types are supported, see the "SETS" section of the nftables manpage
# for details, but currently only the types below are covered by Puppet
type Nftables::SetType = Enum['ipv4_addr', 'ipv6_addr']
