# @summary fail to compile if the running debian codename against the codename passed using a specific operator.
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
function debian::codename::require (
    String                                 $codename,
    Enum['==', '>=', '>', '<', '<=', '!='] $operator = '==',
) {
    unless debian::codename::compare($codename, $operator) {
        fail("node codename does not meet requirement `${debian::codename()} ${operator} ${codename}`")
    }
}
