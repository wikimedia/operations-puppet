# SPDX-License-Identifier: Apache-2.0
type Puppetserver::Hierarchy::RegexLookup = Struct[{
    'name'              => String[1],
    'lookup_key'        => String[1],
    'path'              => String[1],
    'options'           => Struct[{
        'node' => String[1],
    }],
}]
