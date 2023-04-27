# SPDX-License-Identifier: Apache-2.0
# @summary Test if the running debian codename is greater then the codename passed
# @param codename the codename you want to test against
# @param compare_codename An explicit codename to compare otherweise use facter
# @return result of the comparison
# @example Assuming theses functions are compiled for a host running debian buster then
#  debian::codename::gt('buster') == False
#  debian::codename::gt('stretch') == True
#  debian::codename::gt('bullseye') == False
function debian::codename::gt (
    String              $codename,
    Optional[String[1]] $compare_codename = undef,
) >> Boolean {
    debian::codename::compare($codename, '>', $compare_codename)
}
