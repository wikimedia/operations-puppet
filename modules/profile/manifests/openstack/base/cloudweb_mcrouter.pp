# SPDX-License-Identifier: Apache-2.0
# Class profile::openstack::base::cloudweb_mcrouter
#
# Configures a mcrouter cluster which pools all cloudweb hosts
#
class profile::openstack::base::cloudweb_mcrouter () {
    class { 'mcrouter':
        ensure  => absent,
        region  => $::site,
        cluster => 'cloudweb',
        pools   => {},
        routes  => [],
    }

    class { 'memcached':
        version        => absent,
        memcached_user => 'memcache',
    }

    class { 'prometheus::memcached_exporter':
        ensure => absent,
    }
}
