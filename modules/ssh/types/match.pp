# SPDX-License-Identifier: Apache-2.0
type Ssh::Match = Struct[{
    criteria => Enum['User', 'Group', 'Host', 'Address'],
    patterns => Array[String[1]],
    config   => Hash[Ssh::Match::Allowed, String[1]],
}]
