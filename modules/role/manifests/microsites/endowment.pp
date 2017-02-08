# https://endowment.wikimedia.org/
# https://meta.wikimedia.org/wiki/Endowment
class role::microsites::endowment {

    system::role { 'role::microsites::endowment': description => 'endowment.wikimedia.org' }

    include ::endowment
    include ::base::firewall

    ferm::service { 'endowment_http':
        proto => 'tcp',
        port  => '80',
    }

}

