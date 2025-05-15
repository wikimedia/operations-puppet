# SPDX-License-Identifier: Apache-2.0
# vim:sw=4 ts=4 sts=4 et:
# == Class: profile::opensearch::logstash
#
# Provisions OpenSearch backend node for a Logstash cluster.
#
class profile::opensearch::logstash(
    Optional[Stdlib::Fqdn]     $jobs_host    = lookup('profile::opensearch::logstash::jobs_host',    { default_value => undef }),
    Hash                       $curator_jobs = lookup('profile::opensearch::logstash::curator_jobs', { default_value => {} }),
    Opensearch::InstanceParams $dc_settings  = lookup('profile::opensearch::dc_settings'),
) {
    include ::profile::opensearch::server

    ferm::service { 'opensearch-api-from-cumin':
        proto    => 'tcp',
        port     => 9200,
        src_sets => ['CUMIN_MASTERS'],
    }

    # these tasks should only run on one host
    if $jobs_host == $::fqdn {
        include ::profile::prometheus::es_exporter

        $curator_jobs.each |$job_name, $job_config| {
            opensearch::curator::job { $job_name:
              cluster_name => $dc_settings['cluster_name'],
              actions      => $job_config,
            }
        }
    } else {
        # remove jobs from other hosts in the cluster
        $curator_jobs.each |$job_name, $job_config| {
            opensearch::curator::job { $job_name:
              ensure       => absent,
              cluster_name => $dc_settings['cluster_name'],
            }
        }
    }
}
