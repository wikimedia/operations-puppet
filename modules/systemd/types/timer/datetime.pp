# Instead of a regex, Systemd:::Timer::Datetime should be validated by shelling
# out to 'systemd-analyze calendar'. This is done in the definition of
# systemd::timer. See systemd.time(7) for format information.
type Systemd::Timer::Datetime = String
