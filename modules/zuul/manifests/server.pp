# Copyright 2012-2013 Hewlett-Packard Development Company, L.P.
# Copyright 2014 OpenStack Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

# == Class: zuul::server
#
class zuul::server (
) {

    file { '/var/run/zuul':
        ensure  => directory,
        owner   => 'jenkins',
        require => Package['jenkins'],
    }

    file { '/etc/init.d/zuul':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/zuul/zuul.init',
    }

    service { 'zuul':
        name       => 'zuul',
        enable     => true,
        hasrestart => true,
        require    => [
            File['/var/run/zuul'],
            File['/etc/init.d/zuul'],
        ],
    }

    exec { 'zuul-reload':
        command     => '/etc/init.d/zuul reload',
        require     => File['/etc/init.d/zuul'],
        refreshonly => true,
    }
}
