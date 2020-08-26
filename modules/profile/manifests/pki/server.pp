# @summary configure a PKI sevrver
class profile::pki::server () {
    class {'cfssl': }
    $names = [{
        'organisation'      => 'Wikimedia Foundation, Inc',
        'organisation_unit' => 'Technolagy',
        'locality'          => 'San Francisco',
        'state'             => 'California',
        'country'           => 'US',
    }]
    cfssl::csr {'Wikimedia ROOT CA':
        key   => 'ecdsa',
        names => $names,
        sign  => false,
    }
}
