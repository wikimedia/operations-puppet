# SPDX-License-Identifier: Apache-2.0
# == Class: thanos::bucket_query_tools
#
# Analyze Thanos bucket data

class thanos::bucket_query_tools (
) {
    ensure_packages(['python3-boto3', 'python3-urllib3', 'python3-yaml'])

    file { '/usr/local/bin/thanos-bucket-query-export':
        ensure => present,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/thanos/bucket-query/export.py',
    }

    file { '/usr/local/bin/thanos-bucket-query-import':
        ensure => present,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/thanos/bucket-query/import.py',
    }
}
