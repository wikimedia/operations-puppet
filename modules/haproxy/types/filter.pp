# SPDX-License-Identifier: Apache-2.0
type Haproxy::Filter = Struct[{
    'direction' => Enum['in', 'out'],
    'name'      => String[1],
    'size'      => String[1],
    'key'       => String[1],
    'table'     => String[1],
}]
