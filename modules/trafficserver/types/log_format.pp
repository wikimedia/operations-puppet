# SPDX-License-Identifier: Apache-2.0
type Trafficserver::Log_format = Struct[{
    'name'     => String,
    'format'   => String,
    'interval' => Optional[Integer],
}]
