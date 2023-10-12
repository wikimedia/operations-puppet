# SPDX-License-Identifier: Apache-2.0
# = Class: profile::quarry::staging_configure
#
# Sets up a mysql database and configs for use by the Quarry
# staging node.
class profile::quarry::staging_configure (
    String       $dbpass = lookup('profile::quarry::staging_configure::dbpass', {default_value => 'notarealpassword'}),
    String       $oauth_secret_token = lookup('profile::quarry::staging_configure::oauth_secret_token', {default_value => 'blank'}),
    String       $oauth_consumer_token = lookup('profile::quarry::staging_configure::oauth_consumer_token', {default_value => 'blank'}),
    String       $replicapass = lookup('profile::quarry::staging_configure::replica_password', {default_value => 'blank'}),
    String       $replicauser = lookup('profile::quarry::staging_configure::replica_user', {default_value => 'blank'}),
){
    file { ['/data', '/data/project']:
        ensure => directory,
        owner  => 'root',
        before => 'File[/data/project/quarry]'
    }

    file { '/srv/results':
        ensure => 'directory',
        owner  => 'quarry',
        group  => 'quarry',
        mode   => '0755',
    }

    exec {'import mysql':
        path    => '/usr/bin:/usr/sbin',
        command => 'mysql -u root < /srv/quarry/schema.sql',
        require => 'Exec[git_clone_quarry]',
    }

    file { '/srv/quarry/quarry/config.yaml':
        ensure  => file,
        content => template('quarry/staging_config.yaml.erb'),
        require => 'Exec[git_clone_quarry]',
    }

    file { '/root/staging_user.sql':
        ensure  => file,
        content => template('quarry/staging_user.sql.erb'),
        notify  => 'Exec[add quarry user]',
    }

    exec {'add quarry user':
        path        => '/usr/bin',
        command     => 'mysql -u root < /root/staging_user.sql',
        refreshonly => true,
    }
}
