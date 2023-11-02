# SPDX-License-Identifier: Apache-2.0
#
# Control the PHP version used by integration/docroot which is shared between
# https://doc.wikimedia.org/ and https://integration.wikimedia.org/
#
# Example usage:
#
#   include profile::ci::php
#
#   $php_prefix = profile::ci::php::php_prefix   --> 'php7.4'
#   $php_version = profile::ci::php::php_version --> '7.4'
class profile::ci::php {
    if debian::codename::eq('buster') {
        apt::repository { 'wikimedia-php74':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => "${::lsbdistcodename}-wikimedia",
            components => 'component/php74',
        }
        apt::repository { 'icu67':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => 'buster-wikimedia',
            components => 'component/icu67',
        }
    }

    $php_version = debian::codename() ? {
        'buster'   => '7.4',
        'bullseye' => '7.4',  # provided above by component/php74
        default    => fail("${module_name} not supported by ${debian::codename()}")
    }
    $php_prefix = "php${php_version}"
}
