# SPDX-License-Identifier: Apache-2.0
# == Class: profile::pyrra::filesystem::slos::editing

class profile::pyrra::filesystem::slos::editing {

    #lint:ignore:arrow_alignment
    profile::pyrra::filesystem::slos::istio { 'citoid':
        team => 'sre',
        slo_availability_target => '99.5',
        slo_latency_target => '90.0',
        latency_max_seconds_bucket => '30000',
        enable_alerts => false,
        revision => 1,
    }

    profile::pyrra::filesystem::slo { 'wikikube-citoid-success-ratio':
      sloname  => 'citoid-success-ratio',
      team     => 'sre',
      service  => 'citoid',
      revision => 2,
      spec     => {
          'alerting'  => {
              'burnrates' => false
          },
          'target'    => '85.0',
          'window'    => '4w',
          'indicator' => {
              'ratio' => {
                  'errors' => {
                      'metric' => 'citoid_api_user_agent_total{prometheus="k8s", type="mediawikijs", status!~"(2|3).."}',
                  },
                  'total'  => {
                      'metric' => 'citoid_api_user_agent_total{prometheus="k8s", type="mediawikijs"}',
                  },
              },
          },
      },
    }

    pyrra::filesystem::config { 'edit-check-pre-save-checks-ratio.yaml':
      content => to_yaml( {
        'apiVersion' => 'pyrra.dev/v1alpha1',
        'kind' => 'ServiceLevelObjective',
        'metadata' => {
            'name' => 'edit-check-pre-save-checks-ratio',
            'namespace' => 'pyrra-o11y',
            'labels' => {
                'pyrra.dev/team' => 'sre',
                'pyrra.dev/service' => 'edit-check',
            },
        },
        'spec'       => {
            'alerting'  => {
                'burnrates' => false
            },
            'target'    => '99.0',
            'window'    => '4w',
            'indicator' => {
                'ratio' => {
                    'errors' => {
                        'metric' => 'editcheck_sli_presavechecks_shown_vs_available_total',
                    },
                    'total'  => {
                        'metric' => 'editcheck_sli_presavechecks_available_total',
                    },
                },
            },
        },
      })
    }

    #lint:endignore
}
