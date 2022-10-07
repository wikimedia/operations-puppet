# SPDX-License-Identifier: Apache-2.0
# https://wikiworkshop.org (T242374)
class profile::microsites::wikiworkshop {

    httpd::site { 'wikiworkshop.org':
        content => template('profile/wikiworkshop/apache-wikiworkshop.org.erb'),
    }

    wmflib::dir::mkdir_p('/srv/org/wikimedia/wikiworkshop')

    git::clone { 'research/wikiworkshop':
        ensure    => 'latest',
        source    => 'gerrit',
        directory => '/srv/org/wikimedia/wikiworkshop',
        branch    => 'master',
    }
}
