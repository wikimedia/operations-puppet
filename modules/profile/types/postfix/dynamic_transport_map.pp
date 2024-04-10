# SPDX-License-Identifier: Apache-2.0
type Profile::Postfix::Dynamic_transport_map = Struct[{
    type => Postfix::Type::Lookup::Database,
    path => Stdlib::Unixpath,
}]
