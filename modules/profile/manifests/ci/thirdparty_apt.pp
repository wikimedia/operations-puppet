# SPDX-License-Identifier: Apache-2.0
class profile::ci::thirdparty_apt {

    # thirdparty/ci is used on contint to provide a newer Docker package AND Jenkins.
    #
    # Since Bookworm provides a recent enough Docker, we only need it for
    # Jenkins and thirdparty/ci is now named thirdparty/jenkins (which
    # should be configured independently)

    if debian::codename::lt('bookworm') {
        apt::repository { 'thirdparty-ci':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => "${::lsbdistcodename}-wikimedia",
            components => 'thirdparty/ci',
        }
    } else {
        apt::repository { 'thirdparty-jenkins':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => "${::lsbdistcodename}-wikimedia",
            components => 'thirdparty/jenkins',
        }
    }
}
