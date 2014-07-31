# == Class hhvm::packages::dev
#
# Install packages needed for hhvm development such as compiling extensions
#
class hhvm::packages::dev {

    exec { 'install hhvm build dependencies':
        command   => '/usr/bin/apt-get build-dep hhvm',
        logoutput => 'on_failure',
    }

}
