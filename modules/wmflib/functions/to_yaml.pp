# SPDX-License-Identifier: Apache-2.0
# @summary wrap tohe to yaml function allowing one to strip the yaml doc header '---\n'
# @param data the data to convery
# @param strip_header if we should strip the header
# @return The yaml document
function wmflib::to_yaml (
    Any     $data,
    Boolean $strip_header = true,
) {
    $strip_header.bool2str(
        $data.to_yaml[4,-1],
        $data.to_yaml
    )
}
