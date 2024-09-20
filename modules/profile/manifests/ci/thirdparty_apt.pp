# SPDX-License-Identifier: Apache-2.0
class profile::ci::thirdparty_apt {
    apt::repository { 'thirdparty-ci':
      uri        => 'http://apt.wikimedia.org/wikimedia',
      dist       => "${::lsbdistcodename}-wikimedia",
      components => 'thirdparty/ci',
    }
}
