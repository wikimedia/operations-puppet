# @summary Test if the running debian codename against the codename passed using a specific operator
# @param codename the codename you want to test against
# @param operator the comparison operator to use
# @return [Boolean] result of the comparison
# @example Assuming theses functions are compiled for a host running debian buster then
#  debian::codename::compare('buster') == True
#  debian::codename::compare('stretch') == False
#  debian::codename::compare('stretch', '<') == False
#  debian::codename::compare('stretch', '>') == True
#  debian::codename::compare('buster', '>=') == True
#  debian::codename::compare('buster', '<=') == True
function debian::codename::compare (
    String                                 $codename,
    Enum['==', '>=', '>', '<', '<=', '!='] $operator = '==',
) >> Boolean {
    include debian

    $valid_codenames = $debian::supported[$facts['os']['name']]

    unless $codename in $valid_codenames {
        fail("invalid codename (${codename}). supported codenames : ${valid_codenames.keys.join(', ')}")
    }

    $operator ? {
        '>='    => Integer($facts['os']['release']['major']) >= $valid_codenames[$codename],
        '>'     => Integer($facts['os']['release']['major']) > $valid_codenames[$codename],
        '<='    => Integer($facts['os']['release']['major']) <= $valid_codenames[$codename],
        '<'     => Integer($facts['os']['release']['major']) < $valid_codenames[$codename],
        '!='    => Integer($facts['os']['release']['major']) != $valid_codenames[$codename],
        default => Integer($facts['os']['release']['major']) == $valid_codenames[$codename],
    }
}
