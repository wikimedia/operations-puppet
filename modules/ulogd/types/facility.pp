# syslog facility
# https://github.com/inliniac/ulogd2/blob/master/output/ulogd_output_SYSLOG.c#L96
type Ulogd::Facility = Variant[
  Enum['daemon', 'kern', 'user'],
  Pattern[/local[0-7]/],
]
