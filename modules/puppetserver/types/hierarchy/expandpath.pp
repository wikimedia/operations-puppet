# SPDX-License-Identifier: Apache-2.0
type Puppetserver::Hierarchy::ExpandPath = Struct[{
    'name'              => String[1],
    'lookup_key'        => String[1],
    Optional['datadir'] => Stdlib::Unixpath,
    'path'              => String[1],
}]
