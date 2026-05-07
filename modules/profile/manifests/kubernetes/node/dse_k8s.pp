# SPDX-License-Identifier: Apache-2.0
# @summary
#   This profile is used to make OS-level changes on dse-k8s workers
#
# @param set_rbd_readahead
# Whether or not to set readahead for OpenSearch pod RBDs (block devices), ref T419041
class profile::kubernetes::node::dse_k8s (
    Boolean $set_rbd_readahead = lookup('profile::kubernetes::node::dse_k8s::set_rbd_readahead', { default_value => false }),
) {
    # See: https://docs.opensearch.org/2.19/install-and-configure/install-opensearch/index/#important-settings
    # also note that Trixie and newer sets to `1048576`, and the recommended value of `262144` is insufficient
    # in our other OpenSearch clusters.
    sysctl::parameters { 'opensearch':
        values => {
            'vm.max_map_count' => 1048576,
        }
    }

    $set_rbd_cmd    = '/usr/local/sbin/set-rbd-readahead.py'
    $rbd_ensure     = $set_rbd_readahead ? { true => 'present', default => 'absent' }
    $rbd_file_ensure = $set_rbd_readahead ? { true => 'file', default => 'absent' }

    file { $set_rbd_cmd:
        ensure => $rbd_file_ensure,
        source => 'puppet:///modules/profile/kubernetes/node/dse_k8s/set-rbd-readahead.py',
        mode   => '0755',
    }

    systemd::timer::job { 'set-rbd-readahead':
        ensure            => $rbd_ensure,
        description       => 'Set readahead for OpenSearch pod RBDs (block devices)',
        command           => $set_rbd_cmd,
        user              => 'root',
        interval          => { 'start' => 'OnCalendar', 'interval' => '*:0/5' }, # every 5 minutes
        syslog_force_stop => false,
        require           => File[$set_rbd_cmd],
    }
    # This directory can be mounted by certain pods running in this cluster in order to support spark
    # local files. See https://spark.apache.org/docs/3.5.7/running-on-kubernetes.html#local-storage and #T412925
    file { '/srv/spark':
        ensure => directory,
    }
}
