# = class: scap::vhost
#
# Sets up an apache vhost for scap
class scap::vhost(
    $apache_fqdn = $::fqdn,
    $deployable_networks = [],
) {
    include ::apache

    if !defined(File['/srv/deployment']) {
        # Todo: Clean this up. This ownership is disgusting. But it's what
        # we've got as long as trebuchet is around and we don't want to fight
        # ownership on the deploy masters
        file { '/srv/deployment':
            ensure => directory,
            owner  => 'trebuchet',
            group  => 'wikidev',
        }
    }

    apache::site { 'deployment':
        content => template('scap/apache-vhost.erb'),
        require => File['/srv/deployment'],
    }
}
