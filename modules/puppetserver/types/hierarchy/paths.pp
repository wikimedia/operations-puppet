# SPDX-License-Identifier: Apache-2.0
type Puppetserver::Hierarchy::Paths = Struct[{
    'name'              => String[1],
    'paths'             => Array[String[1]],
    Optional['datadir'] => Stdlib::Unixpath,
}]
