# @summary Test if the running debian codename is equal to the codename passed
# @param codename the codename you want to test against
# @return [Boolean] result of the comparison
# @example Assuming theses functions are compiled for a host running debian buster then
#  debian::codename::eq('buster') == True
#  debian::codename::eq('stretch') == False
function debian::codename::eq (
    String $codename,
) >> Boolean {
    debian::codename::compare($codename)
}
