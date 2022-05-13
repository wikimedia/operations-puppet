# SPDX-License-Identifier: Apache-2.0
type Cfssl::Auth_key = Struct[{
    key => Variant[Sensitive[String[16]],Pattern[/^[a-fA-F0-9]{16}$/]],
    type => Enum['standard'],
}]
