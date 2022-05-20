# SPDX-License-Identifier: Apache-2.0
# @summary fail to compile if the running debian codename is not at least equal to the $codename passed
# @param codename the codename you want to test against
# @param operator the comparison operator to us i.e
# @return [Boolean] result of the comparison
# @example Assuming theses functions are compiled for a host running debian buster then
#  debian::codename::require('buster')  # pass/no action
#  debian::codename::compare('stretch') # fail()
#  debian::codename::compare('stretch', '<') # fail()
#  debian::codename::compare('stretch', '>') # pass/no action
#  debian::codename::compare('buster', '>=') # pass/no action
#  debian::codename::compare('buster', '<=') # pass/no action
function debian::codename::require::min (
    String           $codename,
    Optional[String] $msg      = undef,
) {
    debian::codename::require($codename, '>=', $msg)
}
