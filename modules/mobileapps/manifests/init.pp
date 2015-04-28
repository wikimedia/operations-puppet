# == Class: mobileapps
#
# This class installs and configures mobileapps, a node.js service that
# serves HTML content for native mobile applications
#
class mobileapps {

    service::node { 'mobileapps':
        port    => 6624,
    }

}

