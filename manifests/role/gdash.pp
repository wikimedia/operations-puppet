# == Class: role::gdash
#
# Gdash is a dashboarding webapp for Graphite.
# It powers <https://gdash.wikimedia.org>.
#
class role::gdash {
    class { '::gdash':
        server_name     => 'gdash.wikimedia.org',
        graphite_host   => 'https://graphite.wikimedia.org',
        template_source => 'puppet:///files/graphite/gdash',
        options         => {
          title         => 'wmf stats',
          graph_columns => 1,
          graph_height  => 500,
          graph_width   => 1024,
          hide_legend   => false,
          deploy_addon  => template('gdash/deploy_addon.erb'),
        },
    }
}
