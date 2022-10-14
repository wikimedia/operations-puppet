# SPDX-License-Identifier: Apache-2.0
class profile::dumps::generation::server::statsender(
    $xmldumpspublicdir  = lookup('profile::dumps::xmldumpspublicdir'),
) {
    class {'::dumps::generation::server::statsender':
        dumpsbasedir   => $xmldumpspublicdir,
        sender_address => 'noreply.xmldatadumps@wikimedia.org',
        user           => 'dumpsgen',
    }
}
