class profile::wmcs::db::wikireplicas::querysampler (
    Boolean $in_setup = lookup('profile::wmcs::db::wikireplicas::querysampler::in_setup', {default_value => true}),
    String $replicauser = lookup('profile::wmcs::db::wikireplicas::querysampler::replicauser'),
    String $replicapass = lookup('profile::wmcs::db::wikireplicas::querysampler::replicapass'),
    Hash[String,Stdlib::Fqdn] $section_backends = lookup('profile::wmcs::db::wikireplicas::section_backends', {default_value => {'s1' => 'db1.local'}}),
) {
    ensure_packages(['wikireplicas-utils'])
    # This file is now provided by the package above
    file { '/usr/local/sbin/querysampler': ensure => absent }

    file { '/etc/querysampler-config.yaml':
        ensure  => file,
        content => template('profile/wmcs/db/wikireplicas/querysampler-config.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
    }

    systemd::service { 'querysampler':
        # $in_setup should only be false after the cinder volume is ready
        # and the sqlite table is created
        ensure    => $in_setup.bool2str('absent', 'present'),
        content   => systemd_template('wmcs/db/wikireplicas/querysampler'),
        subscribe => File['/etc/querysampler-config.yaml'],
    }
}
