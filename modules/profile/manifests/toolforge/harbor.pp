# SPDX-License-Identifier: Apache-2.0
class profile::toolforge::harbor (
    Stdlib::Unixpath $data_volume = lookup('profile::toolforge::harbor::data_volume', {default_value => '/srv/ops/harbor/data'}),
    String $tlscert = lookup('profile::toolforge::harbor::tlscert', {default_value => 'ec-prime256v1.chained.crt'}),
    String $tlskey = lookup('profile::toolforge::harbor::tlskey', {default_value => 'ec-prime256v1.key'}),
    Stdlib::Unixpath $tlscertdir = lookup('profile::toolforge::harbor::tlscertdir', {default_value => '/etc/acmecerts/toolforge/live'}),
    Boolean $cinder_attached = lookup('profile::toolforge::harbor::cinder_attached', {default_value => false}),
    String[1] $harbor_admin_pwd = lookup('profile::toolforge::harbor::admin_pwd', {default_value => 'insecurityrules'}),
    String[1] $harbor_db_pwd = lookup('profile::toolforge::harbor::db_harbor_pwd', {default_value => 'dummypass'}),
    Stdlib::Host $harbor_db_host = lookup('profile::toolforge::harbor::db_primary', {default_value => 'dummy.db.host'}),
    Stdlib::Fqdn $harbor_url = lookup('profile::toolforge::harbor::url', {default_value => 'dummy.harbor.fqdn'}),
    Profile::Toolforge::Harbor::Robot_accounts $robot_accounts = lookup('profile::toolforge::harbor::robot_accounts', {default_value => {}}),
) {
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

    # Useful packages as harbor runs in docker-compose
    ensure_packages(['postgresql-client', 'redis-tools', 'docker-compose'])

    acme_chief::cert { 'toolforge': }

    $tlscertfile = "${tlscertdir}/${tlscert}"
    $tlskeyfile = "${tlscertdir}/${tlskey}"
    # There must be some kind of puppet fact for this?
    if $cinder_attached {
        # On the cinder volume, expect an untarred installer on /srv/ops.
        # For a fun project, you *can* puppetize everything under
        # /srv/ops/harbor/common/config, however it is all generated by harbor.yml
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
            content => epp(
                'profile/toolforge/harbor/harbor-docker.yaml.epp',
                {
                    harbor_url       => $harbor_url,
                    tlscertfile      => $tlscertfile,
                    tlskeyfile       => $tlskeyfile,
                    harbor_admin_pwd => $harbor_admin_pwd,
                    harbor_db_pwd    => $harbor_db_pwd,
                    harbor_db_host   => $harbor_db_host,
                    data_volume      => $data_volume,
                    robot_accounts   => $robot_accounts,
                }
            ),
        } -> file { '/srv/ops/harbor/data':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        } -> file { '/srv/ops/harbor/data/secret':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        } -> file { '/srv/ops/harbor/data/secret/cert':
            ensure => directory,
            owner  => 10000,
            group  => 10000,
            mode   => '0755',
        }

        # The downloaded default prepare script tries to get certs by
        # mounting / and fails. We just change the volume mount. This only matters
        # on a new install, normally. New versions may need an update here.
        file { '/srv/ops/harbor/prepare':
            ensure  => present,
            mode    => '0555',
            owner   => 'root',
            group   => 'root',
            content => template('profile/toolforge/harbor/prepare.erb'),
            require => File['/srv/ops/harbor'],
        }
        # Harbor's installer copies these in once, we need that every time they
        # update via acmechief. When we do puppetize the entire setup instead of
        # relying on the installer, we can adjust the symlinks and volumes of the
        # proxy service so that the file resources aren't needed and the docker-compose
        # exec can be on the acmechief::cert resource.
        file { '/srv/ops/harbor/data/secret/cert/server.crt':
            ensure  => present,
            mode    => '0600',
            owner   => 10000,
            group   => 10000,
            source  => $tlscertfile,
            require => File['/srv/ops/harbor/data/secret/cert'],
        } -> file { '/srv/ops/harbor/data/secret/cert/server.key':
            ensure    => present,
            mode      => '0600',
            owner     => 10000,
            group     => 10000,
            source    => $tlskeyfile,
            show_diff => false,
            backup    => false,
            require   => File['/srv/ops/harbor/data/secret/cert'],
        }

        $composefile = '/srv/ops/harbor/docker-compose.yml'
        # Reload the nginx container if certs change.
        exec {'reload-nginx-on-tls-update':
            command     => "/usr/bin/docker-compose -f ${composefile} exec -T proxy nginx -s reload",
            subscribe   => File['/srv/ops/harbor/data/secret/cert/server.key'],
            refreshonly => true,
        }

        # I did not find an easy way (avoiding extra wrappers) to use a systemd unit that
        # detected also when the containers were stopped and declared the unit failed if so
        # this is a poor-person's effective alternative
        # the following script relies on docker-compose starting one container per service
        $check_script = @("EOS"/$)
            bash -c "
                want_services=$(docker-compose -f ${composefile} ps --services --all | wc -l);
                got_services=$(docker-compose -f ${composefile} ps | grep Up | wc -l);
                [[ \\\$want_services -ne \\\$got_services ]]
            "
            | EOS
        exec {'ensure-compose-started':
            command => "/usr/bin/docker-compose -f ${composefile} up -d",
            onlyif  => $check_script,
            require => File['/srv/ops/harbor/data/secret/cert/server.key'],
            path    => ['/usr/bin'],
        }
    }
}
