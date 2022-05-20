# SPDX-License-Identifier: Apache-2.0
# @summary perform basic constraints tests and configure variables
#          this class will be called automatically
class debian {
    unless $facts['os']['family'] == 'Debian' {
        fail('Only Debian is supported')
    }
    $supported = {
        'Debian'   => {
            'stretch'  => 9,
            'buster'   => 10,
            'bullseye' => 11,
        }
    }
    unless $facts['os']['name'] in $supported {
        fail("invalid Derivative (${$facts['os']}). supported derivatives: ${supported.keys.join(', ')}")
    }
    # Before a debian release is stable /etc/debian_version, which is what
    # facter uses to calculate the release values, is equal to $codename/sid
    # instead of the expected point release value e.g. 11.0.  This causes this
    # module to fail as it expects theses values to be numbers
    unless $facts['os']['release']['major'] =~ /\d+/ {
        fail("unsupported: facts['os']['release']['major'] (${facts['os']['release']['major']}) is not a number")
    }

}
