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
    }

    file { '/etc/gdash/gdash.yaml':
        content => ordered_json($settings),
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
    }
}
