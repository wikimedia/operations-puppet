# SPDX-License-Identifier: Apache-2.0

class idm::deployment (
    String           $project,
    String           $django_secret_key,
    String           $django_mysql_db_host,
    String           $django_mysql_db_name,
    String           $django_mysql_db_user,
    String           $django_mysql_db_password,
    Stdlib::Unixpath $base_dir,
    String           $deploy_user,
    Boolean          $development,
){
    # We need django from backports to get latest LTS.
    if debian::codename::eq('bullseye') {
        apt::pin { 'python3-django':
            pin      => 'release a=bullseye-backports',
            package  => 'python3-django',
            priority => 1001,
        }
    }

    # Create log directory
    file { '/var/log/idm':
        ensure => directory,
        owner  => $deploy_user,
        group  => $deploy_user,
        mode   => '0700',
    }

    # Create configuration dir.
    file { '/etc/idm':
        ensure => directory,
        owner  => $deploy_user,
        group  => $deploy_user,
        mode   => '0700',
    }

    # Django configuration
    file { '/etc/idm/settings.py':
        ensure  => present,
        content => template('idm/idm-django-settings.erb'),
        owner   => $deploy_user,
        group   => $deploy_user,

    }

    # For staging and production we want to install
    # from Debian packages, but for the development
    # process the latest git version is deployed.
    if($development){
        ensure_packages([
            'python3-redis','python3-django', python3-mysqldb,
            'python3-memcache', 'python3-ldap3'
        ])

        file { $base_dir :
            ensure => directory,
            owner  => $deploy_user,
            group  => $deploy_user,
        }

        git::clone { 'operations/software/bitu':
            ensure    => 'latest',
            directory => "${base_dir}/${project}",
            branch    => 'master',
            owner     => $deploy_user,
            group     => $deploy_user,
            source    => 'gerrit',
        }
    }
}
