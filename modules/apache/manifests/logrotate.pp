# === Class apache::logrotate
#
# Allows defining rotation periodicity and the number of logs to keep
# for any host with apache directly via hiera. Defaults are short so
# that we don't worry about disks filling or about data retention.
class apache::logrotate(
    $period = 'daily',
    $rotate = 30,
    ) {
    # The augeas rule in apache::logrotate needs /etc/logrotate.d/apache2 which
    # is provided by apache2 package
    augeas { 'Apache2 logs':
        lens    => 'Logrotate.lns',
        incl    => '/etc/logrotate.d/apache2',
        changes => [
                    "set rule/schedule ${period}",
                    "set rule/rotate ${rotate}",
        ],
        require => Package['apache2']
    }
}
