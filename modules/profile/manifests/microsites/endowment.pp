# https://endowment.wikimedia.org/
# https://meta.wikimedia.org/wiki/Endowment
class profile::microsites::endowment {
    include ::endowment
    include ::base::firewall

    ferm::service { 'endowment_http':
        proto => 'tcp',
        port  => '80',
    }
}

