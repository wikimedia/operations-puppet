# SPDX-License-Identifier: Apache-2.0
# @summary Run OpenSearch containers using Docker
# @param image_ns namespace of the OCI (docker) image . For our OpenSearch image,
# this works out to the URL of the docker registry inside the `s:
# https://docker-registry.wikimedia.org/`repos/data-engineering`/opensearch/
# @param image_name name of the OCI (docker) image
# @param image_vers version of the OCI (docker) image

class profile::opensearch::cirrus::deployment_prep (
    String $image_ns  = lookup('profile::opensearch::cirrus::oci_image::ns'),
    String $image_name = lookup('profile::opensearch::cirrus::oci_image::name'),
    String $image_vers = lookup('profile::opensearch::cirrus::oci_image::version'),
) {

    require ::profile::docker::engine
    require ::profile::docker::ferm

    service::docker { 'cirrussearch':
        namespace    => $image_ns,
        image_name   => $image_name,
        version      => $image_vers,
        port         => 9200,
        host_network => true,
    }

    profile::auto_restarts::service { 'containerd': }
    profile::auto_restarts::service { 'docker': }

}
