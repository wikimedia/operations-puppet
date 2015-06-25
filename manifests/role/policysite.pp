# https://policy.wikimedia.org/
# T97329
class role::policysite {

    system::role { 'role::policysite': description => 'Upcoming WMF Policy Site - policy.wikimedia.org' }

    include ::policysite

    ferm::service { 'policysite_http':
        proto => 'tcp',
        port  => '80',
    }

}

