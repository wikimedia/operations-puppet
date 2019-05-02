# profile::toolforge::clush::target
#
# Configures a clustershell target
#
# * $master - FQDN of the host that should be allowed SSH access

class profile::toolforge::clush::target(
    String $master      = lookup('profile::toolforge::clush::master'),
    String $sudo_flavor = lookup('sudo_flavor', {default_value => 'sudoldap'}),
) {
    ::clush::target { 'clushuser':
        ensure => present,
    }

    # Allow `clushuser` to SSH into the instance.
    security::access::config { 'clushuser':
        content => "+ : clushuser : ${master}\n",
    }

    ferm::service { $title:
        proto  => 'tcp',
        port   => 22,
        srange => "@resolve((${master}))",
    }

    # Give `clushuser` complete sudo rights
    sudo::user { 'clushuser':
        ensure      => present,
        privileges  => ['ALL = (ALL) NOPASSWD: ALL'],
        sudo_flavor => $sudo_flavor,
    }
}
