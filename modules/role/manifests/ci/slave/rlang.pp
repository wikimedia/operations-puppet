# == Class role::ci::slave::rlang
#
# A continuous integration slave that runs R language based tests.
#
# filtertags: labs-project-integration
class role::ci::slave::rlang {

    requires_realm('labs')

    system::role { 'ci::slave::rlang':
        description => 'CI Jenkins slave for R language testing',
    }

    include role::ci::slave::labs::common
    include profile::rlang::dev

}
