# SPDX-License-Identifier: Apache-2.0
# == Class profile::conftool::state
#
# Provides the confd setup, and yaml files, used to access
# state stored in etcd when needed in puppet.
#
# Should be used with care, this is kind-of an antipattern. It still
# has the advantage over just querying conftool directly from puppet that
# we reduce the number of queries performed, and make their reliability better.

class profile::conftool::state(
    Wmflib::Ensure $ensure = lookup('profile::conftool::state::ensure'),
    String $prefix = lookup('conftool_prefix'),
    Integer $query_interval = lookup('profile::conftool::state::query_interval'),
) {
    class { '::confd':
        ensure   => $ensure,
        prefix   => $prefix,
        interval => $query_interval,
        srv_dns  => "${::site}.wmnet",
    }

    $base_dir = '/etc/conftool-state'
    file { $base_dir:
        ensure => stdlib::ensure($ensure, 'directory'),
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    }

    # state file containing whatever mediawiki state variables we need to access.
    confd::file { "${base_dir}/mediawiki.yaml":
        ensure     => $ensure,
        prefix     => '/mediawiki-config',
        watch_keys => ['/'],
        content    => template('profile/conftool/state-mediawiki.tmpl.erb')
    }
}
