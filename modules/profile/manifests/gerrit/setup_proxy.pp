# SPDX-License-Identifier: Apache-2.0
# Things needed to setup gerrit::proxy (apache)
# without having to install full gerrit.
class profile::gerrit::setup_proxy{

    class { 'sslcert::dhparam': }

    acme_chief::cert { 'gerrit':
        puppet_svc => 'apache2',
    }
}
