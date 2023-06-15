# SPDX-License-Identifier: Apache-2.0
# The ports can be configured in multiple ways:
# - string (legacy Ferm-specific setting), e.g. "23" or "http"
# - a port range passed in the legacy Ferm-specific syntax
# - array of Stdlib::Port (preferred new type)
type Ferm::Port = Variant[
    Pattern[/\d{1,5}:\d{1,5}/],
    Array[Stdlib::Port, 1],
    Stdlib::Port,
    String[1],
]
