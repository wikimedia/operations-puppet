# === Class apache::logrotate
#
# Allows defining rotation periodicity and the number of logs to keep
# for any host with apache directly via hiera. Defaults are what debian sets.
# We might want to make this a bit less long though
class apache::logrotate(
    $period = 'weekly',
    $rotate = 52,
    ) {

    augeas { 'Apache2 logs':
        lens    => 'Logrotate.lns',
        incl    => '/etc/logrotate.d/apache2',
        changes => [
                    "set rule/schedule ${period}",
                    "set rule/rotate ${rotate}"
        ]
    }
}
