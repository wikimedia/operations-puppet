# Type to match logfile parameter
type Ulogd::Logfile = Variant[Enum['syslog', 'stdout'], Stdlib::Unixpath]
