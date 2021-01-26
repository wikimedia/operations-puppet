class profile::wmcs::db::wikireplicas::querysampler (
    Boolean $in_setup = lookup('profile::wmcs::db::wikireplicas::querysampler::in_setup', {default_value => true}),
    String $replicauser = lookup('profile::wmcs::db::wikireplicas::querysampler::replicauser'),
    String $replicapass = lookup('profile::wmcs::db::wikireplicas::querysampler::replicapass'),
    Hash[String,Stdlib::Fqdn] $section_backends = lookup('profile::wmcs::db::wikireplicas::section_backends', {default_value => {'s1' => 'db1.local'}}),
) {
    ensure_packages(['python3-pymysql', 'python3-yaml', 'sqlite3', 'python3-xlsxwriter'])

    # $in_setup should only be false after the cinder volume is ready
    # and the sqlite table is created
    $ensure = $in_setup? {
        true   => 'stopped',
        default => 'running',
    }
    file { '/etc/querysampler-config.yaml':
        ensure  => file,
        content => template('profile/wmcs/db/wikireplicas/querysampler-config.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
    }

    file { '/etc/querysampler.yaml':
        ensure  => file,
        content => template('profile/wmcs/db/wikireplicas/maintain-views.yaml'),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
    }
    file { '/usr/local/sbin/querysampler':
        ensure  => file,
        source  => 'puppet:///modules/profile/wmcs/db/wikireplicas/querysampler.py',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => [Package['python3-yaml', 'python3-pymysql', 'python3-xlsxwriter'],
        ],
    }
    systemd::service { 'querysampler':
        ensure         => 'present',
        content        => systemd_template('wmcs/db/wikireplicas/querysampler'),
        require        => File['/usr/local/sbin/querysampler'],
        subscribe      => File['/etc/querysampler.yaml'],
        service_params => {
            ensure => $ensure,
        }
    }
}
