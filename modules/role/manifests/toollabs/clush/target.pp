# = Class: role::toollabs::clush::target
#
# Sets up an instance to be sshable by the clush::master
# instance that is specified as $master.
#
# == Parameters
# [*master*]
#   fqdn of the instance that should be allowed ssh access.
class role::toollabs::clush::target(
    $master,
) {
    ::clush::target { 'clushuser':
        ensure => present,
    }

    # This allows ssh access for this user from
    # the master. Otherwise PAM only allows ssh
    # from members of the tools project, and this
    # user is not a member of the tools project.
    security::access::config { 'clushuser':
        content => "+ : clushuser : ${master}\n",
    }

    ferm::service { $title:
        proto  => 'tcp',
        port   => 22,
        srange => "@resolve((${master}))",
    }
}
