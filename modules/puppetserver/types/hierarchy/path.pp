# SPDX-License-Identifier: Apache-2.0
type Puppetserver::Hierarchy::Path = Struct[{
    'name'              => String[1],
    'path'              => String[1],
    Optional['datadir'] => Stdlib::Unixpath,
}]
