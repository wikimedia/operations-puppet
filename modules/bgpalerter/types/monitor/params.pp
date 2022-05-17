# SPDX-License-Identifier: Apache-2.0
type Bgpalerter::Monitor::Params = Variant[
    Bgpalerter::Monitor::Params::Generic,
    Bgpalerter::Monitor::Params::Rpki,
    Bgpalerter::Monitor::Params::Roas,
]
