define shinken::arbiter::daemon(
    $daemon_type,
    $address,
    $daemon_name        = $title,
    $spare              = 0,
    $realm              = 'All',
    $timeout            = 3,
    $data_timeout       = 120,
    $max_check_attempts = 3,
    $check_interval     = 60,
    $modules            = [],
    $daemon_config      = undef,
) {
    include ::shinken::arbiter

    $port = $daemon_type ? {
        'broker'      => 7772,
        'scheduler'   => 7768,
        'reactionner' => 7769,
        'poller'      => 7771,
        'default'     => undef,
    }

    if ! $port {
        fail('Wrong daemon_type specified for shinken::arbiter::daemon $title')
    }
    file { "/etc/shinken/${daemon_type}s/${daemon_name}.cfg":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('shinken/daemon.cfg.erb'),
        notify  => Class['shinken::arbiter'],
    }
}
