# Varnish::directors
#
# Writes a dedicated file with nodes and weights

define varnish::common::directors(
    $instance,
    $directors,
    $director_type,
    $options,
    $extraopts)
{
    include role::cache::base
    $tier = $::role::cache::base::cluster_tier
    $conftool_namespace = '/conftool/v1/pools'

    # backends in the primary DC don't need this, so we bail out
    unless defined(Class['Role::Cache::1layer'])
        or ($instance == 'backend'and $tier == 'one') {

        require varnish::common::director_scripts

        $director_list = $instance ? {
            'frontend' => keys($directors),
            'backend'  => $directors[$::mw_primary],
            default    => undef
        }

        if $director_list == undef {
            fail("Invalid instance type ${instance}")
        }

        $dc = $instance ? {
            'frontend' => $::site,
            default    => $::mw_primary,
        }

        $service_name = $instance ? {
            'frontend' => 'varnish-frontend',
            default    => 'varnish'
        }

        # usual old trick
        $group = hiera('cluster', $cluster)

        $keyspace = "${conftool_namespace}/${dc}/${group}/varnish-be"

        confd::file { "/etc/varnish/directors.${instance}.vcl":
            ensure     => present,
            watch_keys => [$keyspace],
            content    => template('varnish/vcl/directors.vcl.tpl.erb'),
            reload     => "/usr/local/bin/confd-reload-vcl ${service_name} ${extraopts}",
        }
    }
}
