# SPDX-License-Identifier: Apache-2.0
# @param prefix the conftool_prefix
# @param instances a hash of instances to configure
class profile::confd (
    String             $prefix    = lookup('conftool_prefix'),
    Hash[String, Hash] $instances = lookup('profile::confd::instances'),
) {
    # inject default values and ensure we always have a main section
    $defaults = {
        'main'    => {
            'prefix'  => $prefix,
            'srv_dns' => "${::site}.wmnet",
        },
    }
    class { 'confd':
        instances => deep_merge($defaults, $instances),
    }
}

