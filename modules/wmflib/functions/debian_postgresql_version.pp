# SPDX-License-Identifier: Apache-2.0
# Return the major release of Postgresql shipped in a given Debian release name
function wmflib::debian_postgresql_version(){
    debian::codename() ? {
        'buster'   => '11',
        'bullseye' => '13',
        'bookworm' => '15',
        'trixie'   => '17',
        default    => fail('unsupported distro'),
    }
}
