# SPDX-License-Identifier: Apache-2.0
# Define: presto::properties
# == Parameters ==
# [*title*]
#   Renders a presto properties file at /etc/presto/$title.properties.
#
# [*properites*]
#   Hash of properties.
#
# [*may_contain_passwords*]
#   If the file will render passwords or not. If yes, 'other' should
#   not be allowed to read.
#
define presto::properties(
    Hash $properties,
    String $owner = 'presto',
    String $group = 'presto',
    Boolean $may_contain_passwords = false,
) {
    if $may_contain_passwords {
        $file_mode = '0440'
    } else {
        $file_mode = '0444'
    }

    file { "/etc/presto/${title}.properties":
        content => template('presto/properties.erb'),
        mode    => $file_mode,
        owner   => $owner,
        group   => $group,
    }
}
