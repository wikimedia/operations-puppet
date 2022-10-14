# SPDX-License-Identifier: Apache-2.0
# Simple nginx HTTP load balancer for ores
#
class profile::labs::ores::lb (
    Array $realservers = lookup('role::labs::ores::lb::realservers'),
    Optional[Boolean] $cache = str2bool(lookup('role::labs::ores::lb::cache',{'default_value' => ''})),
){

    labs_lvm::volume { 'srv':
        mountat => '/srv',
    }

    if $cache {
        file { [
            '/srv/nginx/',
            '/srv/nginx/cache',
            '/srv/nginx/tmp',
        ]:
            ensure => directory,
            owner  => 'www-data',
            group  => 'www-data',
            mode   => '0775',
        }
    }
    nginx::site { 'ores-lb':
        content => template('role/ores/lb.nginx.erb'),
        require => Labs_lvm::Volume['srv'],
    }
}
