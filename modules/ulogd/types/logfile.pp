# SPDX-License-Identifier: Apache-2.0
# Type to match logfile parameter
type Ulogd::Logfile = Variant[Enum['syslog', 'stdout'], Stdlib::Unixpath]
