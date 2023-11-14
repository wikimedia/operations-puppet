# SPDX-License-Identifier: Apache-2.0
# Return the correct PHP version based on the Debian release name.
function wmflib::debian_php_version(){

    debian::codename() ? {
        'buster'   => '7.3',
        'bullseye' => '7.4',
        'bookworm' => '8.2',
        default    => fail('unsupported distro'),
    }
}
