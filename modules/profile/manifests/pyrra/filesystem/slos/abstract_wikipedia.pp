# SPDX-License-Identifier: Apache-2.0
# == Class: profile::pyrra::filesystem::slos::abstract_wikipedia

class profile::pyrra::filesystem::slos::abstract_wikipedia {
    # Backend API combined latency-availability SLO: The percentage of all requests to the backend
    # API that complete within the 10s threshold and receive a non-error response, defined as HTTP
    # status code 200 or 4xx.
    profile::pyrra::filesystem::slo { 'wikifunctions-backend-combined':
        sloname  => 'wikifunctions-backend-combined',
        team     => 'abstract-wikipedia',
        service  => 'wikifunctions',
        revision => 1,
        spec     => {
            'alerting'  => {
                'burnrates' => false
            },
            'target'    => '98.5',
            'window'    => '4w',
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
        }
    }

    profile::pyrra::filesystem::slo { 'wikilambda-parsoid-combined':
        sloname  => 'wikilambda-parsoid-combined',
        team     => 'abstract-wikipedia',
        service  => 'parsoid',
        revision => 1,
        spec     => {
            'alerting'  => {
                'burnrates' => false
            },
            'target'    => '95.0',
            'window'    => '4w',
            'indicator' => {
                'latency' => {
                    'success' => {
                        'metric' => 'mediawiki_WikiLambdaClient_parsoid_to_fragment_handler_seconds_bucket{le="0.1"}',
                    },
                    'total'   => {
                        'metric' => 'mediawiki_WikiLambdaClient_parsoid_to_fragment_handler_seconds_count',
                    },
                },
            },
        }
    }
}
