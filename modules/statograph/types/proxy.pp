# SPDX-License-Identifier: Apache-2.0
type Statograph::Proxy = Struct[{
    'https' => Optional[Stdlib::Httpurl],
    'http'  => Optional[Stdlib::Httpurl],
}]
