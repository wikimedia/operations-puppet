# == Class: gdash
#
# Gdash is a Sinatra webapp that generates Graphite dashboard views
# based on YAML configuration files. This Puppet module provisions Gdash
# with uWSGI as application container.
#
# === Parameters
#
# [*template_source*]
#   Local file system path or Puppet URI for directory containing
#   template data.
#
# [*install_dir*]
#   Install Gdash to this path.
#
# [*graphite_host*]
#   Graphs will be rendered by constructing URLs to this Graphite host.
#
# [*listen_socket*]
#   Serve Gdash via this socket, specified as host:port or /path/to/uds.sock.
#   Default: '/var/run/gdash/gdash.sock'.
#
# [*options*]
#   Gdash configuration options, supplied as a Puppet hash.
#   See <https://github.com/ripienaar/gdash/blob/master/README.md> for
#   a full listing of configuration options.
#
# === Examples
#
#  class { '::gdash':
#    graphite_host   => 'https://graphite.wikimedia.org',
#    template_source => 'puppet:///files/graphite/gdash',
#    install_dir     => '/srv/deployment/gdash/gdash',
#    options         => {
#      title         => 'Wikimedia Foundation Stats',
#      hide_legend   => false,
#      deploy_addon  => template('gdash/deploy_addon'),
#    },
#  }
#
class gdash(
    $template_source = 'puppet:///modules/gdash/templates-empty',
    $install_dir     = '/srv/deployment/gdash/gdash',
    $listen_socket   = '/var/run/gdash/gdash.sock',
    $graphite_host,
    $options,
) {
    $template_dir = '/etc/gdash/templates'

    $settings = {
        graphite    => $graphite_host,
        templatedir => $template_dir,
        options     => $options,
    }

    deployment::target { 'gdash': }

    package { [ 'ruby-rack', 'ruby-sinatra', 'rubygems' ]: }

    file { '/etc/gdash':
        ensure => directory,
    }

    file { '/etc/gdash/gdash.yaml':
        content => ordered_json($settings),
    }

    file { '/etc/gdash/config.ru':
        content => template('gdash/config.ru.erb'),
    }

    file { $template_dir:
        ensure  => directory,
        purge   => true,
        recurse => true,
        force   => true,
        source  => $template_source,
    }

    file { '/var/run/gdash':
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0755',
    }

    uwsgi::app { 'gdash':
        require  => File['/etc/gdash/gdash.yaml', '/etc/gdash/config.ru', '/var/run/gdash'],
        settings => {
            uwsgi => {
                'socket'         => $listen_socket,
                'stats'          => '/var/run/gdash/gdash-stats.sock',
                'rack'           => '/etc/gdash/config.ru',
                'post-buffering' => 4096,  # required by the Rack specification.
                'master'         => true,
                'die-on-term'    => true,
            },
        },
    }
}
