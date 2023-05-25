# SPDX-License-Identifier: Apache-2.0
type Puppetserver::Hierarchy::Glob = Struct[{
    'name'              => String[1],
    'glob'              => String[1],
    Optional['datadir'] => Stdlib::Unixpath,
}]
