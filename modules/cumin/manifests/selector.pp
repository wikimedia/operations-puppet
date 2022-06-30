# SPDX-License-Identifier: Apache-2.0
# == Class cumin::selector
#
# A dummy class that assists with the selection of nodes.
# All cumin targets should include this class.  The
# get_clusters puppet function uses this in its
# query_resources call to find all nodes that include this class.
#
class cumin::selector(String $cluster, String $site) { }
