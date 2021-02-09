# A day of the week in long or abbreviated form
# as accepted by systemd calendar events / timers.
# https://www.freedesktop.org/software/systemd/man/systemd.time.html
type Systemd::Timer::Weekday = Enum[
                          'Mon', 'Monday',
                          'Tue', 'Tuesday',
                          'Wed', 'Wednesday',
                          'Thu', 'Thursday',
                          'Fri', 'Friday',
                          'Sat', 'Saturday',
                          'Sun', 'Sunday'
                          ]
