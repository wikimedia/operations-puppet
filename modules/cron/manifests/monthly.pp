# Type: cron::monthly
# 
# This type creates a monthly cron job via a file in /etc/cron.d
# 
# Parameters:
#   minute - The minute the cron job should fire on. Can be any valid cron minute value.
#     Defaults to '0'.
#   hour - The hour the cron job should fire on. Can be any valid cron hour value.
#     Defaults to '0'.
#   date - The date the cron job should fire on. Can be any valid cron date value.
#     Defaults to '1'.
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
#   cron::monthly {
#     'delete old log files':
#       minute      => '1',
#       hour        => '7',
#       date        => '28',
#       environment => [ 'MAILTO="admin@example.com"' ],
#       command     => 'find /var/log -type f -ctime +30 -exec rm -f {} \;';
#   }

define cron::monthly( $minute = 0, $hour = 0, $date = 1, $environment = [], $user = 'root', $command ) {
  cron::job {
    $title:
      minute      => $minute,
      hour        => $hour,
      date        => $date,
      month       => '*',
      weekday     => '*',
      user        => $user,
      environment => $environment,
      command     => $command;
  }
}

