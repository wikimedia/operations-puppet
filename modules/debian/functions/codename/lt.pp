# SPDX-License-Identifier: Apache-2.0
# @summary Test if the running debian codename is less then the codename passed
# @param codename the codename you want to test against
# @return [Boolean] result of the comparison
# @example Assuming theses functions are compiled for a host running debian buster then
#  debian::codename::lt('buster') == False
#  debian::codename::lt('stretch') == False
#  debian::codename::lt('bullseye') == True
function debian::codename::lt (
    String $codename,
) >> Boolean {
    debian::codename::compare($codename, '<')
}
