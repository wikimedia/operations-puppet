class diamond::generic() {

    #these are notes just for initial rollout and testing:
    #tungsten: 10.64.0.18
    #(labs) athens graphite server: 10.68.17.73
    #Once https://gerrit.wikimedia.org/r/#/c/131449/ merges
    #start batching in groups of 10 to start, for now current statsd can't
    #accept multiple metrics
    class { 'diamond':
        settings => {
            enabled => 'true',
            host    => '10.64.0.18',
            port    => '8125',
        },
    }

    diamond::collector { 'CPU':
        settings => {
            enabled   => 'true',
            percore   => 'false',
            normalize => 'true',
        },
    }

    diamond::collector { 'Network':
        settings => {
            enabled => 'true',
        },
    }
}
