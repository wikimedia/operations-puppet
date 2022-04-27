# SPDX-License-Identifier: Apache-2.0
type Prometheus::Blackbox::HeaderSpec = Struct[{
    header        => String[1],
    regexp        => String[1],
    allow_missing => Optional[Boolean],
}]
