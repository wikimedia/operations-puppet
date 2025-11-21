# SPDX-License-Identifier: Apache-2.0
# pattern is for rack name, like 'a1', 'b2', etc
# basically, something like:
# eqiad:
#   a1: 1
#   a2: 2
# codfw:
#   b1: 3
#   b2: 4
type Profile::Wmcs::Vlan_Mapping = Hash[
    Wmflib::Sites, Hash[Pattern[/\A[a-z][0-9]/], Network::VLANTag, 1],
    1
]
