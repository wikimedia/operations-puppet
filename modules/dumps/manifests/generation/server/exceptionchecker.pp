class dumps::generation::server::exceptionchecker(
    $dumpsbasedir = undef,
    $user         = undef,
)  {
    file { '/usr/local/bin/dumps_exception_checker.py':
        ensure => 'present',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/generation/dumps_exception_checker.py',
    }

    cron { 'dumps-exception-checker':
        ensure      => 'present',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        command     => "/usr/bin/python3 /usr/local/bin/dumps_exception_checker.py ${dumpsbasedir} 480 latest",
        user        => $user,
        minute      => '40',
        hour        => '*/8',
        require     => File['/usr/local/bin/dumps_exception_checker.py'],
    }
}
