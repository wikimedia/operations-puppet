# @summary Test if the running debian codename is not equal to the codename passed
# @param codename the codename you want to test against
# @return [Boolean] result of the comparison
# @example Assuming theses functions are compiled for a host running debian buster then
#  debian::codename::ne('buster') == False
#  debian::codename::ne('stretch') == True
function debian::codename::ne (
    String $codename,
) >> Boolean {
    debian::codename::compare($codename, '!=')
}
