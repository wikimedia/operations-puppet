class profile::toolforge::harbor (
    Stdlib::Unixpath $data_volume = lookup('profile::toolforge::harbor::data_volume', {default_value => '/srv/harbor/data'}),
    Stdlib::Unixpath $tlscert = lookup('profile::toolforge::harbor::tlscert', {default_value => '/etc/acmecerts/toolforge/live/ec-prime256v1.chained.crt'}),
    Stdlib::Unixpath $tlskey = lookup('profile::toolforge::harbor::tlskey', {default_value => '/etc/acmecerts/toolforge/live/ec-prime256v1.key'}),
    Boolean $cinder_attached = lookup('profile::toolforge::harbor::cinder_attached', {default_value => false}),
    String $harbor_init_pwd = lookup('profile::toolforge::harbor::init_pwd', {default_value => 'insecurityrules'}),
    String $harbor_db_pwd = lookup('profile::toolforge::harbor::db::harbor_pwd'),
    Stdlib::Host $harbor_db_host = lookup('profile::toolforge::harbor::db::primary'),
    Stdlib::Fqdn $harbor_url = lookup('profile::toolforge::harbor::url'),
) {
    # Easy way to get docker and such from our repos.
    require profile::wmcs::kubeadm::client
    class { 'kubeadm::docker': }

    # Useful packages and harbor runs in docker-compose
    ensure_packages(['postgresql-client', 'redis-tools', 'docker-compose'])

    acme_chief::cert { 'toolforge': }

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
    }
}
