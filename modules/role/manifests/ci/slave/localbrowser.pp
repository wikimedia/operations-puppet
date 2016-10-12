class role::ci::slave::localbrowser {
    requires_realm('labs')

    system::role { 'role::ci::slave::localbrowser':
        description => 'CI Jenkins slave for running tests in local browsers',
    }

    include role::ci::slave::labs::common
    include ::zuul
    include contint::browsers
}

