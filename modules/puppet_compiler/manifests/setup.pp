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
    exec { 'create puppet ssl dir':
        command     => "/usr/bin/puppet cert --ssldir ${vardir}/ssl --vardir ${vardir} list -a",
        creates     => "${vardir}/ssl/ca/inventory.txt",
        user        => $user,
        cwd         => $homedir,
        environment => "HOME=${homedir}",
        require     => Exec['create puppet directories'],
    }

    # Install the puppet catalog diff face
    exec { 'install puppet catalog diff':
        command     => '/usr/bin/puppet module install zack-catalog_diff',
        creates     => "${homedir}/.puppet/modules/catalog_diff",
        user        => $user,
        cwd         => $homedir,
        environment => "HOME=${homedir}",
    }

}
