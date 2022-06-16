# SPDX-License-Identifier: Apache-2.0
# @api private
# == Class php::default_extensions
#
# Private class that takes care of installing the base extensions
# that are part of the basic debian installation of php.
#
# This is only used as part of the php class, should not be called without it.
#
class php::default_extensions {
    if !defined(Class['php']) {
        fail('php::default_extensions is a private class and should only be called within the php class')
    }
    # Basic extensions we want to configure everywhere
    $base_extensions = [
        'calendar',
        'ctype',
        'exif',
        'fileinfo',
        'ftp',
        'gettext',
        'iconv',
        'json',
        'phar',
        'posix',
        'readline',
        'shmop',
        'sockets',
        'sysvmsg',
        'sysvsem',
        'sysvshm',
        'tokenizer'
    ]

    # None of these extensions need to install a package - they're part of the core
    # package on debian. So, pass an empty string as a package name.
    php::extension { $base_extensions:
        install_packages => false,
        versions         => $php::versions,
        priority         => 20,
    }

    # Hi-priority extensions
    php::extension{
        default:
            install_packages => false,
            priority         => 10,
            versions         => $php::versions,;
        'pdo':
            ;
        'opcache':
            config => {'zend_extension' => 'opcache.so'},;
    }
}
