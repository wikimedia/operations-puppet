# SPDX-License-Identifier: Apache-2.0
# set_ecs_template_version.rb
# Logstash Ruby script that sets template_version based on the @metadata configured mapping.
# @version 1.0.0
#
# Example Logstash Filter:
# ruby {
#   path => "/etc/logstash/filter_scripts/set_ecs_template_version.rb"
# }
#
# The above filter configuration would affect an event like so:
#
# Event In -> {
#   "ecs": {
#     "version": "1.7.0"
#   },
#   "@metadata": {
#     "ecs_version_map": {
#       "default": "1.11.0"
#       "1": "1.11.0"
#     },
#     "template_version" => "1.0.0"
#   }
# }
#
# Event Out -> {
#   "ecs": {
#     "version": "1.7.0"
#   },
#   "@metadata": {
#     "ecs_version_map": {
#       "default": "1.11.0"
#       "1": "1.11.0"
#     },
#     "template_version" => "1.11.0"
#   }
# }

def register(params) end

def filter(event)
  unless event.get('[ecs][version]').nil? # skip if no ecs version
    mapping = event.get('[@metadata][ecs_version_map]').to_hash
    major, minor, patch = event.get("[ecs][version]").split('.')
    [
      "#{major}.#{minor}.#{patch}",
      "#{major}.#{minor}",
      "#{major}",
      'default'
    ].each do |variant|
      if mapping[variant]
        event.set('[@metadata][template_version]', mapping[variant])
        break
      end
    end
  end
  [event]
end
