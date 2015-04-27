# https://policy.wikimedia.org/
# T97329
class policysite {

    include ::apache
    include ::apache::mod::headers

    file { '/srv/org/wikimedia/policy':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    apache::site { 'policy.wikimedia.org':
        source => 'puppet:///modules/policysite/policy.wikimedia.org',
    }

}
