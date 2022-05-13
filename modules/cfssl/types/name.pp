# SPDX-License-Identifier: Apache-2.0
type Cfssl::Name = Struct[{
    country             => String[2,2],
    locality            => String[1],
    organisation        => String[1],
    organisational_unit => String[1],
    state               => String[1],
}]
