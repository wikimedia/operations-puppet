# SPDX-License-Identifier: Apache-2.0
# Kubernetes mediawiki configuration
# * virtual hosts
# * mcrouter pools

class profile::kubernetes::deployment_server::mediawiki(
    Stdlib::Unixpath $general_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),

) {
    file { "${general_dir}/mediawiki":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    }
    include profile::kubernetes::deployment_server::mediawiki::config
    include profile::kubernetes::deployment_server::mediawiki::mwdebug_deploy
    include profile::kubernetes::deployment_server::mediawiki::builder
    include profile::kubernetes::deployment_server::mediawiki::release
}
