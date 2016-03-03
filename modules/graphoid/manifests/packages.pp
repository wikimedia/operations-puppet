# == Class: graphoid::packages
#
# Installs the packages needed by graphoid
#
class graphoid::packages {

    service::packages { 'graphoid':
        pkgs     => ['libcairo2', 'libgif4', 'libjpeg62-turbo', 'libpango1.0-0'],
        dev_pkgs => ['libcairo2-dev', 'libgif-dev', 'libpango1.0-dev',
        'libjpeg62-turbo-dev'],
    }

}
