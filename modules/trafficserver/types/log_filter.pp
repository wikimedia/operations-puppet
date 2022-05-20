# SPDX-License-Identifier: Apache-2.0
type Trafficserver::Log_filter = Struct[{
    'name'      => String,
    'action'    => Enum['accept', 'reject', 'wipe'],
    'condition' => String,
}]
