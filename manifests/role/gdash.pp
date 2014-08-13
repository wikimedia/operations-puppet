# == Class: role::gdash
#
# Gdash is a dashboarding webapp for Graphite.
# It powers <https://gdash.wikimedia.org>.
#
class role::gdash {
    class { '::gdash':
        graphite_host   => 'https://graphite.wikimedia.org',
        template_source => 'puppet:///files/gdash',
        options         => {
          title         => 'WMF stats',
          graph_columns => 1,
          graph_height  => 500,
          graph_width   => 1024,
          hide_legend   => false,
          deploy_addon  => template('gdash/deploy_addon.erb'),
        },
    }

    include ::apache
    include ::apache::mod::uwsgi

    apache::site { 'gdash.wikimedia.org':
        content => template('apache/sites/gdash.wikimedia.org.erb'),
    }

    # We're on the backend, no https here.
    monitor_service { 'gdash':
        description   => 'gdash.wikimedia.org',
        check_command => 'check_http_url!gdash.wikimedia.org!/',
    }
}
