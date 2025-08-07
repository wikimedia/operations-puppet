# SPDX-License-Identifier: Apache-2.0
# == Class: profile::pyrra::filesystem::slos::abstract_wikipedia

class profile::pyrra::filesystem::slos::abstract_wikipedia {
    # Backend API combined latency-availability SLO: The percentage of all requests to the backend
    # API that complete within the 10s threshold and receive a non-error response, defined as HTTP
    # status code 200 or 4xx.
    pyrra::filesystem::config { 'wikifunctions-backend-combined.yaml':
      content => to_yaml({
        'apiVersion' => 'pyrra.dev/v1alpha1',
        'kind'       => 'ServiceLevelObjective',
        'metadata'   => {
            'name'      => 'wikifunctions-backend-combined',
            'namespace' => 'pyrra-o11y',
            'labels'    => {
                'pyrra.dev/team'    => 'abstract-wikipedia',
                'pyrra.dev/service' => 'wikifunctions',
            },
        },
        'spec'       => {
            'alerting'  => {
                'burnrates' => false
            },
            'target'    => '98.5',
            'window'    => '12w',
            'indicator' => {
                'latency' => {
                    'success' => {
                        'metric' => 'mediawiki_WikiLambda_mw_to_orchestrator_api_call_seconds_bucket{status=~"200|4..", le="10"}',
                    },
                    'total'   => {
                        'metric' => 'mediawiki_WikiLambda_mw_to_orchestrator_api_call_seconds_count',
                    },
                },
            },
        },
      })
    }
}
