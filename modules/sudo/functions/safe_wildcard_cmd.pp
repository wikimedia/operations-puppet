# SPDX-License-Identifier: Apache-2.0
# @summary this function takes a command and a path containing a wildcard and
#         returns a sudo command spec with additional negations to avoid path traversal
# @param $cmd the sudo command to run
# @param $wildpath a unixpath containing a wildcard to expand
# @return an sudo safe command spec of the form
#         "${cmd} ${wildpath}, !${cmd} ${wildpath} *, !${cmd} ${wildpath}..*
function sudo::safe_wildcard_cmd(Stdlib::Unixpath $cmd, Stdlib::Unixpath $wildpath) {
    if $wildpath !~ /\*$/ {
        "${cmd} ${wildpath}"
    } else {
        [' *', '..*'].reduce("${cmd} ${wildpath}") |$memo, $value| {
            "${memo}, !${cmd} ${wildpath}${value}"
        }
    }
}
