class swift::swiftrepl (
  $destination_site,
  $source_site = $::site,
  $ensure = present,
) {
    require_package('python-cloudfiles')
    $basedir = '/srv/software'
    $account = 'mw:media'

    group { 'swiftrepl':
        ensure => $ensure,
        name   => 'swiftrepl',
    }

    user { 'swiftrepl':
        ensure     => $ensure,
        name       => 'swiftrepl',
        home       => $basedir,
        shell      => '/bin/sh',
        comment    => 'swiftrepl user',
        gid        => 'swiftrepl',
        managehome => false,
        system     => true,
    }

    file { [$basedir, '/var/log/swiftrepl']:
        ensure  => ensure_directory($ensure),
        owner   => 'swiftrepl',
        group   => 'swiftrepl',
        mode    => '0750',
        require => User['swiftrepl'],
    }

    tidy { '/var/log/swiftrepl':
        age     => '15w',
        recurse => true,
        matches => '*.log',
    }

    git::clone { 'operations/software':
        ensure    => $ensure,
        directory => $basedir,
        branch    => 'master',
        owner     => 'swiftrepl',
        group     => 'swiftrepl',
    }

    file { '/usr/local/bin/swiftrepl-mw':
        ensure => $ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => "puppet:///modules/${module_name}/swiftrepl-mw.sh",
    }

    systemd::service { 'swiftrepl-mw.service':
        ensure  => $ensure,
        content => template('swift/swiftrepl-mw.service.erb'),
    }

    $timer_interval = $source_site ? {
        'eqiad' => 'Mon *-*-* 08:00:00',
        'codfw' => 'Wed *-*-* 08:00:00',
    }

    systemd::timer { 'swiftrepl-mw':
        ensure          => $ensure,
        timer_intervals => [{
            'start'    => 'OnCalendar',
            'interval' => $timer_interval,
        }],
    }

    # TODO(filippo) credentials for both source and destination sites are needed
    #file { "${basedir}/swiftrepl/swiftrepl.conf":
    #    owner   => 'swiftrepl',
    #    group   => 'swiftrepl',
    #    mode    => '0700',
    #    content => "${account}\n${password}\nhttps://ms-fe.svc.${destination_site}.wmnet/auth/v1.0\n",
    #}
}
