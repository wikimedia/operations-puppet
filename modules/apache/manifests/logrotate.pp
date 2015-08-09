# === Class apache::logrotate
#
# Allows defining rotation periodicity and the number of logs to keep
# for any host with apache directly via hiera.
class apache::logrotate(
    $rotate = 7,
    $keep = 52,
    ) {
    file_line { 'periodicity':
        ensure => present,
        path   => '/etc/logrotate.d/apache2',
        match  => '^\trotate\s+\d+$',
        line   => "\trotate ${rotate}"
    }

    file_line { 'archiving':
        ensure => present,
        path   => '/etc/logrotate.d/apache2',
        match  => '^\tkeep\s+\d+$',
        line   => "\trotate ${keep}"
    }
}
