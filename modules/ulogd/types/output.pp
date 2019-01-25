# type to define allowed input types
# the outputs that are commented out are not implmented by this module
type Ulogd::Output = Enum[
  'LOGEMU',
  'JSON',
  'SYSLOG',
  'XML',
# 'SQLITE3',
  'OPRINT',
  'GPRINT',
  'NACCT',
  'PCAP',
# 'PGSQL',
# 'MYSQL',
# 'DBI',
# 'GRAPHITE',
]
