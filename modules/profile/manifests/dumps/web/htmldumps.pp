# SPDX-License-Identifier: Apache-2.0
class profile::dumps::web::htmldumps {

    class {'::dumps::web::htmldumps': htmldumps_server => 'htmldumper1001.eqiad.wmnet'}

    ferm::service { 'html_dumps_http':
        proto => 'tcp',
        port  => '80',
    }
}
