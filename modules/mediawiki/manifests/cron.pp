# Define compatible with the puppet base cron define, that will prevent scripts from actually running


define mediawiki::cron(
    $ensure,
    $command,
    $environment=undef,
    $hour=undef,
    $minute=undef,
    $month=undef,
    $monthday=undef,
    $special=undef,
    $target=undef,
    $user='root',
    $weekday=undef,
) {
    $safe_title = regsubst($title, '\W', '_', 'G')
    $cron_wrapper = "/usr/local/bin/mw-cron-${safe_title}"
    file { $cron_wrapper:
        ensure  => $ensure,
        content => template('mediawiki/cron_wrapper.erb'),
        mode    => '0550',
        owner   => $user,
        group   => 'root'
    }

    cron { $title:
        ensure      => $ensure,
        command     => $cron_wrapper,
        environment => $environment,
        hour        => $hour,
        minute      => $minute,
        month       => $month,
        monthday    => $monthday,
        special     => $special,
        target      => $target,
        user        => $user,
        weekday     => $weekday,
        require     => [File[$cron_wrapper],Confd::File['/etc/mediawiki-active-dc']]
    }
}
