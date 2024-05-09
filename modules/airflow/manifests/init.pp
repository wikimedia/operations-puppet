# SPDX-License-Identifier: Apache-2.0
# == Class airflow
# Base class for declaring airflow::instances.
# Installs the WMF airflow .deb package as a conda environment into /usr/lib/airflow.
#
# Creates an 'airflow' control systemd service that all airflow::instance services
# declare themselves PartOf.  This can be used for easy managing of all local airflow services.
#
# Also installs a check_cmd used for NRPE checks when an airflow::instance
# has $monitoring_enabled => true.
#
# === Parameters
# [*ensure*]
#   Puppet ensure param fo airflow package and other files and services.
#   Default: installed
#
# [*version*]
#   Version to use when installing airflow package.
#   If undef, will use 'installed', allowing any version.
#   Default: undef.
#
class airflow(
    Wmflib::Ensure      $ensure = 'present',
    Array[Stdlib::Fqdn] $mail_smarthost = [],
    Optional[String]    $version = undef
) {
    # If $ensure is absent, then also ensure that
    # airflow package is absent.  Else
    # either use 'installed', or the provided $airflow_version.
    $ensure_airflow_package = $ensure ? {
        'absent' => 'absent',
        default  => $version ? {
            undef   => 'installed',
            default => $version
        }
    }

    package { 'airflow':
        ensure => $ensure_airflow_package,
    }

    # Path to where airflow conda env is installed
    $airflow_prefix = '/usr/lib/airflow'

    # Generic nrpe check for running a command and checking its retval.
    # Used for custom Airflow CLI checks.
    file { '/usr/local/bin/check_cmd':
        ensure => $ensure,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/airflow/check_cmd.sh'
    }

    # Wrapper script around find to remove old log files and directories.
    # Each airflow::instance can set up a systemd timer to call this script
    # and clean its log files.
    file { '/usr/local/bin/clean_logs':
        ensure => $ensure,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/airflow/clean_logs.sh'
    }

    systemd::service { 'airflow':
        ensure  => $ensure,
        content => systemd_template('airflow'),
        restart => true,
    }

}
