# SPDX-License-Identifier: Apache-2.0
type Profile::Postfix::Static_transport_map = Struct[{
    type    => Postfix::Type::Lookup::Database,
    content => String[1],
}]
