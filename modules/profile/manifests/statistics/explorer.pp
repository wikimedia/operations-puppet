# SPDX-License-Identifier: Apache-2.0
# == Class profile::statistics::explorer
#
class profile::statistics::explorer {

    include ::profile::statistics::base

    # optimize/protect stat host workflows, see T373446
    class { '::statistics::optimize': }

    class { '::deployment::umask_wikidev': }

    # enable CPU performance governor; see T362922
    class { 'cpufrequtils': }

    # Include the MySQL research password at
    # /etc/mysql/conf.d/analytics-research-client.cnf
    # and only readable by users in the
    # analytics-privatedata-users group.
    statistics::mysql_credentials { 'analytics-research':
        group => 'analytics-privatedata-users',
    }
}