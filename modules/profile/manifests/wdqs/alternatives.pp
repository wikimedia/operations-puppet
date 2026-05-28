# SPDX-License-Identifier: Apache-2.0
# = Class: profile::wdqs::alternatives
#
# This profile configures the resources that are required
# on the wdqs::alternatives nodes.
#
class profile::wdqs::alternatives {
    firewall::service { 'wdqs-backend-dlever':
        desc     => 'This is the qlever SPARQL interface',
        proto    => 'tcp',
        port     => 7001,
        src_sets => ['ANALYTICS_NETWORKS'],
    }

    firewall::service { 'wdqs-backend-blazegraph':
        desc     => 'This is the Blazegraph SPARQL interface',
        proto    => 'tcp',
        port     => 9999,
        src_sets => ['ANALYTICS_NETWORKS'],
    }
# needed for moving data in and out of the DSE Ceph cluster's S3 buckets, ref
# T427348
    ensure_packages('s3cmd')
}

