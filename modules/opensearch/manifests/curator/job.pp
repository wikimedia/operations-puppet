# SPDX-License-Identifier: Apache-2.0
# == Define: opensearch::curator::job
#
# Define a curator Actions file and set to run on an interval
#
# == Parameters:
# - $cluster_name: The cluster name these actions are expected to run against.  Required.
#       References the curator cluster configuration created by Opensearch::Instance.
# - $ensure: Whether the config should exist. Default present.
# - $action: Action to perform.
#       https://www.elastic.co/guide/en/elasticsearch/client/curator/current/actions.html
# - $description: Description.
#       https://www.elastic.co/guide/en/elasticsearch/client/curator/current/actionfile.html#description
# - $options: Hash of options.
#       https://www.elastic.co/guide/en/elasticsearch/client/curator/current/options.html
# - $filters: Array of filters.
#       https://www.elastic.co/guide/en/elasticsearch/client/curator/current/filters.html
# - $actions: Hash containing the actions to perform.
#       https://www.elastic.co/guide/en/elasticsearch/client/curator/current/actionfile.html
# - $interval: Systemd timer interval.
# - $user: User to run Systemd timer as.
#
# == Sample usages:
#
#   opensearch::curator::job { 'logstash':
#     $cluster_name => 'production-elk7-codfw',
#     $action       => 'forcemerge',
#     $description  => 'regularly force merge these indexes',
#     $options      => {
#       'max_num_segments' => 1,
#       'delay' => 120,
#       'continue_if_exception' => false
#     }
#     $filters => [
#       { 'filtertype' => 'pattern',
#         'kind'       => 'regex'
#         'exclude'    => true  # exclude special indexes
#         'value'      => '^\..*' },
#       { 'filtertype' => 'age',
#         'source'     => 'creation_date',
#         'direction'  => 'older',
#         'unit'       => 'days'
#         'unit_count' => 2 }
#     ]
#   }
#
#   opensearch::curator::job { 'logstash':
#     cluster_name => 'production-elk7-codfw',
#     actions      => {
#       1 => {
#         'action' => 'forcemerge',
#         'description' => 'regularly force merge these indexes',
#         'options' => {
#           'max_num_segments' => 1,
#           'delay' => 120,
#           'continue_if_exception' => false
#         },
#         'filters' => [
#           { 'filtertype' => 'pattern',
#             'kind' => 'prefix',
#             'value' => 'logstash-' },
#           { 'filtertype' => 'age',
#             'source' => 'creation_date',
#             'direction' => 'older',
#             'unit' => 'days',
#             'unit_count' => 2 }
#         ]
#       },
#       2 => {
#         'action' => 'forcemerge',
#         'description' => 'regularly force merge these indexes',
#         'options' => {
#           'max_num_segments' => 1,
#           'delay' => 120,
#           'continue_if_exception' => false
#         },
#         'filters' => [
#           { 'filtertype' => 'pattern',
#             'kind' => 'prefix',
#             'value' => 'ecs-' },
#           { 'filtertype' => 'age',
#             'source' => 'creation_date',
#             'direction' => 'older',
#             'unit' => 'days',
#             'unit_count' => 2 }
#         ]
#       }
#     }
#   }
#
define opensearch::curator::job(
  String                   $cluster_name,
  Wmflib::Ensure           $ensure        = 'present',
  Optional[String]         $action        = undef,
  String                   $description   = $title,
  Hash                     $options       = {},
  Array[Hash]              $filters       = [],
  Optional[Hash]           $actions       = undef,
  Systemd::Timer::Schedule $interval      = { 'start' => 'OnCalendar', 'interval' => '*-*-* 00:42:00' },
  String                   $user          = 'root',
) {
  if ($actions) {
    $actions_real = { 'actions' => $actions }
  } else {
    $actions_real = {
      'action' => {
        '1' => {
          'action'      => $action,
          'description' => $description,
          'options'     => $options,
          'filters'     => $filters,
        }
      }
    }
  }

  opensearch::curator::config { "${title}_actions":
    ensure  => $ensure,
    content => to_yaml($actions_real),
  }

  systemd::timer::job { "curator_actions_${title}":
    ensure      => $ensure,
    description => "OpenSearch Curator action ${title}",
    command     => "/usr/bin/curator --config /etc/curator/${cluster_name}.yaml /etc/curator/${title}_actions.yaml",
    user        => $user,
    interval    => $interval,
    require     => Opensearch::Curator::Config["${title}_actions"],
  }
}
