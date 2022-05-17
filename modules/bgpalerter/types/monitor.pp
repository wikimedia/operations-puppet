# SPDX-License-Identifier: Apache-2.0
type Bgpalerter::Monitor = Struct[{
    file             => Bgpalerter::Monitor::File,
    name             => String[1],
    channel          => String[1],
    params           => Bgpalerter::Monitor::Params,
    'params.noProxy' => Optional[Boolean],
}]
