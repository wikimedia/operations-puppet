# SPDX-License-Identifier: Apache-2.0
type Statograph::Metric::Graphite = Struct[{
    'statuspage_id' => String,
    'query'         => String,
    'graphite'      => Stdlib::Httpurl,
}]
