class base::sysctl::core_dumps (
    String[1] $core_dump_pattern = '/var/tmp/core/core.%h.%e.%p.%t',
) {
    file { '/var/tmp/core':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '1773',
    }

    # Write core dumps to /var/tmp/core/core.<host>.<executable>.<pid>.<timestamp>.
    sysctl::parameters { 'core_dumps':
        values  => { 'kernel.core_pattern' => $core_dump_pattern, },
        require => File['/var/tmp/core'],
    }

    # Remove core dumps with atime > one week.
    # TODO: to change this to a systemd::timer as tidy is not that efficient
    tidy { '/var/tmp/core':
        age     => '1w',
        recurse => 1,
        matches => 'core.*',
    }

}
