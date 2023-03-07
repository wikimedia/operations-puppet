# SPDX-License-Identifier: Apache-2.0
type Puppetserver::Hierarchy = Variant[
    Puppetserver::Hierarchy::Httpyaml,
    Puppetserver::Hierarchy::Path,
    Puppetserver::Hierarchy::Paths,
]
