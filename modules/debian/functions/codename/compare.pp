# SPDX-License-Identifier: Apache-2.0
# @summary Test if the running debian codename against the codename passed using a specific operator
# @param codename the codename you want to test against
# @param operator the comparison operator to use
# @param compare_codename An explicit codename to compare otherweise use facter
# @return result of the comparison
# @example Assuming theses functions are compiled for a host running debian buster then
#  debian::codename::compare('buster') == True
#  debian::codename::compare('stretch') == False
#  debian::codename::compare('stretch', '<') == False
#  debian::codename::compare('stretch', '>') == True
#  debian::codename::compare('buster', '>=') == True
#  debian::codename::compare('buster', '<=') == True
function debian::codename::compare (
    String                                 $codename,
    Enum['==', '>=', '>', '<', '<=', '!='] $operator         = '==',
    Optional[String[1]]                    $compare_codename = undef,
) >> Boolean {
    include debian

    $valid_codenames = $debian::supported[$facts['os']['name']]

    unless $codename in $valid_codenames {
        fail("invalid codename (${codename}). supported codenames : ${valid_codenames.keys.join(', ')}")
    }
    if $compare_codename and !($compare_codename in $valid_codenames) {
        fail("invalid codename (${compare_codename}). supported codenames : ${valid_codenames.keys.join(', ')}")
    }

    $major = $compare_codename ? {
        undef   => $debian::major,
        default => $valid_codenames[$compare_codename],
    }

    $operator ? {
        '>='    => $major >= $valid_codenames[$codename],
        '>'     => $major > $valid_codenames[$codename],
        '<='    => $major <= $valid_codenames[$codename],
        '<'     => $major < $valid_codenames[$codename],
        '!='    => $major != $valid_codenames[$codename],
        default => $major == $valid_codenames[$codename],
    }
}
