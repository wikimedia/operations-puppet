# == Class: mathoid::packages
#
# Installs the packages needed by Mathoid
#
class mathoid::packages {

    # Pending fix for <https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=742347>
    # require_package('node-jsdom')

    service::packages { 'mathoid':
        pkgs     => ['librsvg2-2'],
        dev_pkgs => ['librsvg2-dev'],
    }

}
