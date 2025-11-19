# SPDX-License-Identifier: Apache-2.0
class profile::elasticsearch::relforge (
    Array[Stdlib::IP::Address] $cumin_masters = lookup('cumin_masters'),
) {
    include ::profile::elasticsearch::cirrus
    include ::profile::elasticsearch::monitor::base_checks

    # the relforge cluster is serving labs, it should never be connected from
    # production, except from cumin masters to run cookbooks
    $srange = join($cumin_masters, ' ')
    ::ferm::service {
        default:
            ensure => present,
            proto  => 'tcp',
            srange => "(${srange})",
        ;
        'elastic-main-https-9243':
            port => '9243',
        ;
        'elastic-small-alpha-https-9443':
            port => '9443',
        ;
    }
}
