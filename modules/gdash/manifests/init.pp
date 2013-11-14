# == Class: gdash
#
# Gdash is a Sinatra webapp that generates Graphite dashboard views
# based on YAML configuration files.
#
class gdash(
    $template_source = 'puppet:///modules/gdash/templates-empty',
    $install_dir,
    $graphite_host,
    $options,
) {
    $template_dir = '/etc/gdash/templates'

    $settings = {
        graphite    => $graphite_host,
        templatedir => $template_dir,
        options     => $options,
    }

    file { '/etc/gdash':
        ensure => directory,
    }

    file { $template_dir:
        ensure  => directory,
        purge   => true,
        recurse => true,
        force   => true,
        source  => $template_source,
        before  => Uwsgi::App['gdash'],
    }

    file { '/etc/gdash/gdash.yaml':
        content => ordered_json($settings),
        before  => Uwsgi::App['gdash'],
    }

    file { '/opt/gdash':
        ensure => directory,
    }

    file { '/opt/gdash/public':
        ensure => link,
        target => "${install_dir}/public",
    }

    file { '/opt/gdash/public/config.ru':
        content => template('gdash/config.ru.erb'),
        before  => Uwsgi::App['gdash'],
    }

    file { '/var/run/gdash':
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0755',
        before => Uwsgi::App['gdash'],
    }

    uwsgi::app { 'gdash':
        settings => {
            uwsgi => {
                'socket'         => '/var/run/gdash/gdash.sock',
                'stats'          => '/var/run/gdash/gdash-stats.sock',
                'rack'           => '/opt/gdash/public/config.ru',
                'post-buffering' => 4096,  # required by the Rack specification.
                'master'         => true,
                'die-on-term'    => true,
            },
        },
    }
}
