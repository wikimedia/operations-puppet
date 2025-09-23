# SPDX-License-Identifier: Apache-2.0
# == Class: profile::pyrra::filesystem::slos::readers_growth

class profile::pyrra::filesystem::slos::readers_growth {

    # Note: this is a service served by the Istio Gateway, but we don't use
    # the Istio metrics since they don't offer the 200ms latency bucket.
    # We use metrics generated directly by the service.
    profile::pyrra::filesystem::slo { 'charts-renderer-latency':
        sloname  => 'charts-renderer-latency',
        team     => 'readers-growth',
        service  => 'charts',
        revision => 1,
        spec     => {
            'alerting'  => {
                'burnrates' => false
            },
            'target'    => '90.0',
            'window'    => '4w',
            'indicator' => {
                'latency'  => {
                    'success' => {
                        'metric' => 'chart_renderer_duration_milliseconds_bucket{le="200"}',
                    },
                    'total'   => {
                        'metric' => 'chart_renderer_duration_milliseconds_count',
                    },
                },
            },
        },
    }

    profile::pyrra::filesystem::slo { 'charts-client-side-availability':
        sloname  => 'charts-client-side-availability',
        team     => 'readers-growth',
        service  => 'charts',
        revision => 1,
        spec     => {
            'alerting'  => {
                'burnrates' => false
            },
            'target'    => '99.5',
            'window'    => '4w',
            'indicator' => {
                'ratio' => {
                    'errors' => {
                        'metric' => 'mediawiki_Chart_render_failure_total',
                    },
                    'total'  => {
                        'metric' => 'mediawiki_Chart_render_end_total',
                    },
                },
            },
        },
    }
}
