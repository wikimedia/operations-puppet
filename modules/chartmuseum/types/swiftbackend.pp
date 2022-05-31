# SPDX-License-Identifier: Apache-2.0
# ChartMuseum::SwiftBackend configures the swift backend for ChartMuseum.
#
type ChartMuseum::SwiftBackend = Struct[{
    'auth_url'  => Stdlib::HTTPSUrl,
    'container' => String[1],
    'user'      => String[1],
    'key'       => String[1],
}]
