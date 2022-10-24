class profile::toolforge::harbor (
    Stdlib::Unixpath $data_volume = lookup('profile::toolforge::harbor::data_volume', {default_value => '/srv/harbor/data'}),
    String $tlscert = lookup('profile::toolforge::harbor::tlscert', {default_value => 'ec-prime256v1.chained.crt'}),
    String $tlskey = lookup('profile::toolforge::harbor::tlskey', {default_value => 'ec-prime256v1.key'}),
    Stdlib::Unixpath $tlscertdir = lookup('profile::toolforge::harbor::tlscertdir', {default_value => '/etc/acmecerts/toolforge/live'}),
    Boolean $cinder_attached = lookup('profile::toolforge::harbor::cinder_attached', {default_value => false}),
    String $harbor_init_pwd = lookup('profile::toolforge::harbor::init_pwd', {default_value => 'insecurityrules'}),
    String $harbor_db_pwd = lookup('profile::toolforge::harbor::db::harbor_pwd'),
    Stdlib::Host $harbor_db_host = lookup('profile::toolforge::harbor::db::primary'),
    Stdlib::Fqdn $harbor_url = lookup('profile::toolforge::harbor::url'),
) {
    if debian::codename::lt('bullseye') {
        # Easy way to get docker and such from our repos.
        require profile::wmcs::kubeadm::client
        class { 'kubeadm::docker': }
    } else {
        # we don't need any special repo for bullseye
        ensure_packages(['docker.io'])
        service { 'docker':
            ensure => 'running'
        }

        file { '/etc/docker/daemon.json':
            source  => 'puppet:///modules/toolforge/docker-config.json',
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            notify  => Service['docker'],
            require => Package['docker.io'],
        }
    }

    # Useful packages and harbor runs in docker-compose
    ensure_packages(['postgresql-client', 'redis-tools', 'docker-compose'])

    acme_chief::cert { 'toolforge': }

    $tlscertfile = "${tlscertdir}/${tlscert}"
    $tlskeyfile = "${tlscertdir}/${tlskey}"
    # There must be some kind of puppet fact for this?
    if $cinder_attached {
        file { '/srv/ops':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        } -> file { '/srv/ops/harbor':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        } -> file { '/srv/ops/harbor/harbor.yml':
            ensure  => present,
            mode    => '0600',
            content => template('profile/toolforge/harbor/harbor-docker.yaml.erb'),
        }

        # The downloaded default prepare script tries to get certs by
        # mounting / and fails. We just change the volume mount. This only matters
        # on a new install, normally. New versions may need an update here.
        file { '/srv/ops/harbor/prepare':
            ensure  => present,
            mode    => '0655',
            owner   => 'root',
            group   => 'root',
            content => template('profile/toolforge/harbor/prepare.erb'),
            require => File['/srv/ops/harbor'],
        }
    }
}
