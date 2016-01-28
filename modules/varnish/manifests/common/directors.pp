# Varnish::directors
#
# Writes a dedicated file with nodes and weights

define varnish::common::directors(
    $instance,
    $directors,
    $extraopts)
{
    $conftool_namespace = '/conftool/v1/pools'

    # backends in the primary DC don't need this, so we bail out
    require varnish::common::director_scripts

    $director_list = $instance ? {
        /frontend/ => keys($directors),
        /backend/  => keys($directors),
        default    => undef
    }

    if $director_list == undef {
        fail("Invalid instance type ${instance}")
    }

    $def_dc = $instance ? {
        /frontend/ => $::site,
        default    => $::mw_primary,
    }

    $service_name = $instance ? {
        'frontend' => 'varnish-frontend',
        'backend'  => 'varnish',
        default    => "varnish-${instance}",
    }

    # usual old trick
    $group = hiera('cluster', $::cluster)
    $def_service = 'varnish-be'

    $keyspaces_str = inline_template("<%= @directors.values.map{ |v| \"#{@conftool_namespace}/#{v['dc'] || @def_dc}/#{@group}/#{v['service'] || @def_service}\" }.join('|') %>")
    $keyspaces = sort(unique(split($keyspaces_str, '\|')))
    confd::file { "/etc/varnish/directors.${instance}.vcl":
        ensure     => present,
        watch_keys => $keyspaces,
        content    => template('varnish/vcl/directors.vcl.tpl.erb'),
        reload     => "/usr/local/bin/confd-reload-vcl ${service_name} ${extraopts}",
    }
}
