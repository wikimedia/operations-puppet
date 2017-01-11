# === Class apache::logrotate
#
# Allows defining rotation periodicity and the number of logs to keep
# for any host with apache directly via hiera. Defaults are short so
# that we don't worry about disks filling or about data retention.
class apache::logrotate(
    $period = 'daily',
    $rotate = 30,
    ) {

    augeas { 'Apache2 logs':
        lens    => 'Logrotate.lns',
        incl    => '/etc/logrotate.d/apache2',
        changes => [
                    "set rule/schedule ${period}",
                    "set rule/rotate ${rotate}",
        ],
    }
}
