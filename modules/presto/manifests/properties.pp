# Define: presto::properties
# == Parameters ==
# [*title*]
#   Renders a presto properties file at /etc/presto/$title.properties.
#
# [*properites*]
#   Hash of properties.
#
define presto::properties(Hash $properties) {
    file { "/etc/presto/${title}.properties":
        content => template('presto/properties.erb'),
        mode    => '0444',
    }
}
