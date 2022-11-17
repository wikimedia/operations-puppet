# SPDX-License-Identifier: Apache-2.0
type Cfssl::Name = Struct[{
    Optional['country']             => String[2,2],
    Optional['locality']            => String[1],
    Optional['organisation']        => String[1],
    Optional['organisational_unit'] => String[1],
    Optional['state']               => String[1],
}]
