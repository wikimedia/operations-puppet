# SPDX-License-Identifier: Apache-2.0
# @summary
# A dummy class that assists with the selection of nodes.  All cumin targets should include this
# class.  The wmflib::get_clusters puppet function uses this in its  wmflib::puppetdb_query call
# to find all nodes that include this class.
class cumin::selector(String $cluster, String $site) { }
