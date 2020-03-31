class profile::cescout {
    require_package('cescout')

    # enable system-wide proxy for cescout
    file { '/etc/profile.d/cescout.sh':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('cescout/cescout.sh.erb'),
    }
}
