# == Class: phabricator::mail
#
# Sets up special routing for exim handler
#
# === Parameters
#
# [*phab_bot*]
#   Key/Value parameters for the email bot to function
#
# [*address_routing*]
#   Key/value email address to project id mappings
#
# [*direct_comments_allowed*]
#   Key/value project name to comma separated domain list
#
# === Examples
#
#    class { '::phabricator::mail':
#        address_routing         => { maint-announce => 3},
#        direct_comments_allowed => { testproj => 'cisco.com,gmail.com'},
#        phab_bot => { root_dir   => '/srv/phab/phabricator/',
#                      env         => 'default',
#                      username    => 'phabot',
#                      host        => 'http://myhost/api/',
#                      certificate => $certificate,
#        },
#    }
#
# See modules/phabricator/files/phab_epipe.py for more usage info
#
class phabricator::mail(
        $phab_bot                = {},
        $address_routing         = {},
        $direct_comments_allowed = {},
) {

    file { '/usr/local/bin/phab_epipe.py':
        ensure  => file,
        source => 'puppet:///modules/phabricator/phab_epipe.py',
        owner   => mail,
        group   => mail,
    }

    file { '/etc/phab_epipe.conf':
        ensure  => file,
        content => template('phabricator/phab_epipe.conf.erb'),
        owner   => mail,
    }
}

