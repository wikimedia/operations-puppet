# Type: cron::daily
# 
# This type creates a daily cron job via a file in /etc/cron.d
# 
# Parameters:
#   minute - The minute the cron job should fire on. Can be any valid cron minute value.
#     Defaults to '0'.
#   hour - The hour the cron job should fire on. Can be any valid cron hour value.
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
#   cron::daily {
#     'mysql backup':
#       minute      => '1',
#       hour        => '3',
#       environment => [ 'PATH="/usr/sbin:/usr/bin:/sbin:/bin"' ],
#       command     => 'mysqldump -u root my_db >/mnt/backups/db/daily/my_db_$(date "+%Y%m%d").sql';
#   }

define cron::daily( $minute = 0, $hour = 0, $environment = [], $user = 'root', $command ) {
  cron::job {
    $title:
      minute      => $minute,
      hour        => $hour,
      date        => '*',
      month       => '*',
      weekday     => '*',
      user        => $user,
      environment => $environment,
      command     => $command;
  }
}

