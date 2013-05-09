# Type: cron::weekly
# 
# This type creates a cron job via a file in /etc/cron.d
# 
# Parameters:
#   minute - The minute the cron job should fire on. Can be any valid cron minute value.
#     Defaults to '0'.
#   hour - The hour the cron job should fire on. Can be any valid cron hour value.
#     Defaults to '0'.
#   weekday - The day of the week the cron job should fire on. Can be any valid cron weekday value.
#     Defaults to '0'.
#   environment - An array of environment variable settings.
#     Defaults to an empty set ([]).
#   user - The user the cron job should be executed as.
#     Defaults to 'root'.
#   command - The command to execute.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#   cron::weekly {
#     'delete old temp files':
#       minute      => '1',
#       hour        => '4',
#       weekday     => '7',
#       environment => [ 'MAILTO="admin@example.com"' ],
#       command     => 'find /tmp -type f -ctime +7 -exec rm -f {} \;';
#   }

define cron::weekly( $minute = 0, $hour = 0, $weekday = 0, $environment = [], $user = 'root', $command ) {
  cron::job {
    $title:
      minute      => $minute,
      hour        => $hour,
      date        => '*',
      month       => '*',
      weekday     => $weekday,
      user        => $user,
      environment => $environment,
      command     => $command;
  }
}

