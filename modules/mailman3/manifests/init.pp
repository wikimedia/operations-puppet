# SPDX-License-Identifier: Apache-2.0
# == Class mailman3
#
# Provisions all the mailman3 software needed to
# run mailing lists on a single host.
class mailman3 (
    Stdlib::Fqdn $host,
    Stdlib::Fqdn $db_host,
    String $db_name,
    String $db_user,
    String $db_password,
    String $webdb_name,
    String $webdb_user,
    String $webdb_password,
    String $api_password,
    String $web_secret,
    String $archiver_key,
    String $service_ensure = 'running',
    Optional[String] $memcached = undef,
) {

    # We do not want to use the dbconfig system
    # that tries to apply database updates on
    # package install.
    package { 'dbconfig-no-thanks':
        ensure => present
    }

    package { 'dbconfig-mysql':
        ensure => absent
    }

    class { '::mailman3::listserve':
        host           => $host,
        service_ensure => $service_ensure,
        db_host        => $db_host,
        db_name        => $db_name,
        db_user        => $db_user,
        db_password    => $db_password,
        api_password   => $api_password,
    }

    class { '::mailman3::web':
        host           => $host,
        service_ensure => $service_ensure,
        db_host        => $db_host,
        db_name        => $webdb_name,
        db_user        => $webdb_user,
        db_password    => $webdb_password,
        api_password   => $api_password,
        secret         => $web_secret,
        archiver_key   => $archiver_key,
        memcached      => $memcached,
    }
}
