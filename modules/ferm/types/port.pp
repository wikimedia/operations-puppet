# SPDX-License-Identifier: Apache-2.0
type Ferm::Port = Variant[
    Pattern[/\d{1,5}:\d{1,5}/],
    Stdlib::Port,
]
