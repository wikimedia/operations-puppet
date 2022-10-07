# SPDX-License-Identifier: Apache-2.0
# https://bienvenida.wikimedia.org (T207816)
class profile::microsites::bienvenida {

    httpd::site { 'bienvenida.wikimedia.org':
        content => template('profile/bienvenida/apache-bienvenida.wikimedia.org.erb'),
    }

    wmflib::dir::mkdir_p('/srv/org/wikimedia/bienvenida')

    git::clone { 'wikimedia/campaigns/eswiki-2018':
        ensure    => 'present',
        source    => 'gerrit',
        directory => '/srv/org/wikimedia/bienvenida',
        branch    => 'master',
    }
}
