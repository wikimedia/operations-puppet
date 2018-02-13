# == Class profile::java::analytics
#
# Installs Java packages chosen by the Analytics
# team and used among various projects like Hadoop,
# Druid, etc. Consistency is essential to allow
# interoperability among various clusters.
#
class profile::java::analytics {

    require_package('openjdk-8-jdk')

    # Make sure file.encoding is UTF-8 for all java processes.
    # This should help avoid bugs like T128295.
    file_line { 'java_tool_options_file_encoding_utf_8':
        line => 'JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8"',
        path => '/etc/environment',
    }
}