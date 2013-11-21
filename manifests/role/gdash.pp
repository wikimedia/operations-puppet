# == Class: role::gdash
#
# Gdash is a dashboarding webapp for Graphite.
# It powers <https://gdash.wikimedia.org>.
#
class role::gdash {
    deployment::target { 'gdash': }

    class { '::gdash':
        graphite_host   => 'https://graphite.wikimedia.org',
        template_source => 'puppet:///files/graphite/gdash',
        install_dir     => '/srv/deployment/gdash/gdash',
        options         => {
          title         => 'wmf stats',
          graph_columns => 1,
          graph_height  => 500,
          graph_width   => 1024,
          hide_legend   => false,
          deploy_addon  => 'target=alias(color(dashed(drawAsInfinite(deploy.sync-common-file)),"c0c0c080"),"sync-common-file")&target=alias(lineWidth(color(drawAsInfinite(deploy.sync-common-all),"gold"),2),"sync-common-all")&target=alias(lineWidth(color(drawAsInfinite(deploy.scap),"white"),2),"scap deploy")',
        },
    }
}
