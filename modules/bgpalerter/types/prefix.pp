# SPDX-License-Identifier: Apache-2.0
type Bgpalerter::Prefix = Struct[{
    description         => String[1],
    asn                 => Array[Integer[1]],
    ignoreMorespecifics => Boolean,
    ignore              => Boolean,
    group               => String[1],
}]
