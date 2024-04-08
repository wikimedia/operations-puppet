# SPDX-License-Identifier: Apache-2.0
# Common ferm class for labstore servers.

class profile::wmcs::nfs::ferm {
    ferm::service { 'labstore_nfs_nfs_service':
        proto  => 'tcp',
        port   => '2049',
        srange => '(($LABS_NETWORKS $CLOUD_NETWORKS_PUBLIC))',
    }

    # Mount wikidata dumps via NFS, this is faster than rate-limited HTTP
    # See T222349 and T316236 for more context.
    ferm::service { 'query_service_nfs_service':
      proto  => 'tcp',
      port   => '2049',
      srange => '@resolve((wdqs1022.eqiad.wmnet wdqs1023.eqiad.wmnet wdqs1024.eqiad.wmnet wcqs2001.codfw.wmnet wdqs2009.codfw.wmnet wdqs2010.codfw.wmnet))',
    }
}
