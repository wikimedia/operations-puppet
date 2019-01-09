# Systemd::Timer::DateTime will match only normalized forms of systemd.time (see man page systemd.time)
# along with the special forms that include asterisks for "every", such as *-*-* as every day or Mon *-*-* for every
# Monday.  In its present form, it doesn't match some of the special phrases that can be used with a timer.

type Systemd::Timer::DateTime = Pattern[/\A((Mon(,|\.\.)?|Tue(,|\.\.)?|Wed(,|\.\.)?|Thu(,|\.\.)?|Fri(,|\.\.)?|Sat(,|\.\.)?|Sun(,|\.\.)?)*\s){0,1}(\d{4}|\*)-(\d{2}|\*)-(\d{2}|\*)\s(\d{2}(\/\d{1,2}){0,1}|\*):(\d{2}(\/\d{1,2}){0,1}|\*):(\d{2}(\/\d{1,2}){0,1}|\*)\Z/]
