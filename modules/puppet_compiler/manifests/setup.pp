# SPDX-License-Identifier: Apache-2.0
# === Class puppet_compiler::setup
#
# Sets up the puppet environment

class puppet_compiler::setup($vardir, $user, $homedir) {
    # Install the puppet var dir files
    exec { 'create puppet directories':
        command     => "/usr/bin/puppet master --compile test --vardir ${vardir}",
        creates     => "${vardir}/yaml",
        user        => $user,
        cwd         => $homedir,
        environment => "HOME=${homedir}",
        require     => File[$vardir],
    }

    # Create the ssl directory, and the puppet ca
    exec { 'Generate CA for the compiler':
        command     => "/usr/bin/puppet cert --ssldir ${vardir}/ssl --vardir ${vardir} generate ${::fqdn}",
        creates     => "${vardir}/ssl/certs/${::fqdn}.pem",
        user        => $user,
        cwd         => $homedir,
        environment => "HOME=${homedir}",
        require     => Exec['create puppet directories'],
    }
}
