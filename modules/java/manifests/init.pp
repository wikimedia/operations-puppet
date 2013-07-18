# == Class java
# Installs the default java package using the
# java::install define.
#
class java {
    java::install { 'default-java': }
}