# SPDX-License-Identifier: Apache-2.0
# thirdparty/ci is used on contint/bullseye to provide a newer Docker package AND Jenkins.
#
# Since Bookworm and later provide a recent enough Docker, we only need it for
# Jenkins and thirdparty/ci is now named thirdparty/jenkins (which
# should be configured independently).
class profile::ci::thirdparty_apt {

    if debian::codename::lt('bookworm') {
        apt::repository { 'thirdparty-ci':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => "${::lsbdistcodename}-wikimedia",
            components => 'thirdparty/ci',
        }
    } else {
        # From bookworm onwards, the apt sources must use a `Signed-by:` line.
        apt::repository { 'thirdparty-jenkins':
            uri          => 'http://apt.wikimedia.org/wikimedia',
            dist         => "${::lsbdistcodename}-wikimedia",
            components   => 'thirdparty/jenkins',
            keyfile_path => '/etc/apt/keyrings/wikimedia-archive-keyring.gpg',
        }
    }
}
