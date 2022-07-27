# SPDX-License-Identifier: Apache-2.0

# This role to be removed once fully mimgrated to an-airflow1004
# https://phabricator.wikimedia.org/T312858
class role::analytics_cluster::airflow::platform_eng_legacy {
    system::role { 'analytics_cluster::airflow::platform_eng_legacy':
        description => 'Legacy Airflow instance for the Platform Engineering team in the Analytics Cluster',
    }

    include ::profile::analytics::cluster::airflow
}
