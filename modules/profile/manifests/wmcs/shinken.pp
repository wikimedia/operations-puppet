class profile::wmcs::shinken(
    $keystone_host   = lookup('profile::openstack::eqiad1::keystone_host'),
    $keystone_port   = lookup('profile::openstack::base::keystone::public_port'),
    $puppet_enc_host = lookup('profile::wmcs::shinken::puppet_enc_host'),
    $ircbot          = lookup('profile::wmcs::shinken::ircbot'),
    $ircbot_nick     = lookup('profile::wmcs::shinken::ircbot_nick'),
    $ircbot_server   = lookup('profile::wmcs::shinken::ircbot_server'),
) {
    class { '::shinken':
        auth_secret     => 'This is insecure, should switch to using private repo',
        site            => $::site,
        keystone_host   => $keystone_host,
        keystone_port   => $keystone_port,
        puppet_enc_host => $puppet_enc_host,
    }

    #  Allow shinken to run the check_dhcp test as root.  It doesn't
    #   work as user.
    sudo::user { 'shinken_sudo_for_dhcp':
        user       => 'shinken',
        privileges => ['ALL=(root) NOPASSWD: /usr/lib/nagios/plugins/check_dhcp'],
    }

    # Basic WMCS instance & infrastructure monitoring
    shinken::config { 'basic-infra-checks':
        source => 'puppet:///modules/profile/wmcs/shinken/basic-infra-checks.cfg',
    }
    shinken::config { 'basic-instance-checks':
        source => 'puppet:///modules/profile/wmcs/shinken/basic-instance-checks.cfg',
    }

    if $ircbot {
        class { '::shinken::ircbot':
            nick   => $ircbot_nick,
            server => $ircbot_server,
        }
    }

    # toolforge specific bits
    shinken::config { 'toolforge':
        source => 'puppet:///modules/profile/wmcs/shinken/toolforge.cfg',
    }

    # beta specific bits
    shinken::config { 'beta':
        source => 'puppet:///modules/profile/wmcs/shinken/beta.cfg',
    }
}
