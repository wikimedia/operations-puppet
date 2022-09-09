# SPDX-License-Identifier: Apache-2.0
# == define scap::dsh::group
#
# Manages a scap dsh group.
#
# Group entries can be defined either by explicitly providing a
# host list, or defining scap::dsh::group::$title in hiera. Also,
# this can gather all non-inactive nodes from one or more conftool
# pools.
define scap::dsh::group(
    Optional[Array[Stdlib::Fqdn]] $hosts = undef,
    Optional[Array] $conftool            = undef,
){

    $host_list = $hosts ? {
        undef   => lookup("scap::dsh::${title}", {'default_value' => []}),
        default => $hosts,
    }

    if $conftool {
        $default_datacenters = ['eqiad', 'codfw']
        # Add the default datacenters if they don't exist
        $data = $conftool.map |$x| {
            {'datacenters' => $default_datacenters} + $x
        }

        # And extract the confd keys
        $k = $data.map |$datum| {
            $datum['datacenters'].map |$y| {
                "/${y}/${datum['cluster']}/${datum['service']}"
            }
        }
        $keys = flatten($k)

        confd::file { "/etc/dsh/group/${title}":
            ensure     => present,
            prefix     => '/pools',
            watch_keys => $keys,
            content    => template('scap/dsh/dsh-group-conftool.tpl.erb')
        }
    } else {
        file { "/etc/dsh/group/${title}":
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template('scap/dsh/dsh-group.erb'),
        }
    }

}
