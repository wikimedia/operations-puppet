# SPDX-License-Identifier: Apache-2.0
# Return the PHP version used by the Wikimedia wikis based on the Debian release name.
# This only covers the distros for which we build the internal PHP packages powering
# the wikis
function wmflib::wmf_php_version(){

    debian::codename() ? {
        'buster'   => '7.4',
        'bullseye' => '7.4',
        default    => fail('unsupported distro'),
    }
}
