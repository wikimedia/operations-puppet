# SPDX-License-Identifier: Apache-2.0
# @summary Run OpenSearch containers using Docker
# @param image_ns namespace of the OCI (docker) image . For our OpenSearch image,
# this works out to the URL of the docker registry inside the `s:
# https://docker-registry.wikimedia.org/`repos/data-engineering`/opensearch/
# @param image_name name of the OCI (docker) image
# @param image_vers version of the OCI (docker) image
# @param opensearch_uid UNIX user ID of OpenSearch OCI image
# @param opensearch_gid UNIX group ID of OpenSearch OCI image

class profile::opensearch::cirrus::deployment_prep (
    String $image_ns  = lookup('profile::opensearch::cirrus::oci_image::ns'),
    String $image_name = lookup('profile::opensearch::cirrus::oci_image::name'),
    String $image_vers = lookup('profile::opensearch::cirrus::oci_image::version'),
    String $opensearch_uid = lookup('profile::opensearch::cirrus::oci_image::opensearch_uid', {default_value => '999'}),
    String $opensearch_gid = lookup('profile::opensearch::cirrus::oci_image::opensearch_gid', {default_value => '999'}),
    String $base_data_dir = lookup('profile::opensearch::base_data_dir'),
    String $heap_memory = lookup('profile::opensearch::common_settings::heap_memory')
) {

    require ::profile::docker::engine
    require ::profile::docker::ferm
    require ::profile::tlsproxy::envoy

    service::docker { 'cirrussearch':
        namespace    => $image_ns,
        image_name   => $image_name,
        version      => $image_vers,
        port         => 9200,
        host_network => true,
        volume       => true,
        bind_mounts  =>   { '/srv/opensearch'                => '/usr/share/opensearch/data',
                            '/etc/opensearch/opensearch.yml' => '/usr/share/opensearch/config/opensearch.yml',
                            '/var/log/opensearch'            => '/usr/share/opensearch/logs'
        },
        environment  => { 'OPENSEARCH_JAVA_OPTIONS' => "-Xms${heap_memory} -Xmx${heap_memory}" }
    }

    profile::auto_restarts::service { 'containerd': }
    profile::auto_restarts::service { 'docker': }
    # $base_data_dir defaults to '/srv/opensearch'
    file { [ $base_data_dir, '/var/log/opensearch' ]:
        ensure => 'directory',
        owner  => $opensearch_uid,
        group  => $opensearch_gid,
        mode   => '0700'
    }

    file { '/etc/opensearch':
        ensure => 'directory',
        owner  => $opensearch_uid,
        group  => $opensearch_gid,
        mode   => '0700'
    }

    file { '/etc/opensearch/opensearch.yml':
        ensure => 'file',
        owner  => $opensearch_uid,
        group  => $opensearch_gid,
        mode   => '0440',
        source => 'puppet:///modules/opensearch/opensearch-deployment-prep.yml',
        notify => Systemd::Service['cirrussearch']
    }

}
