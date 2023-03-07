# SPDX-License-Identifier: Apache-2.0
type Puppetserver::Hierarchy::Httpyaml = Struct[{
    'name'      => String[1],
    'data_hash' => Enum['cloudlib::httpyaml'],
    'uri'       => Stdlib::HTTPUrl,
}]
