# SPDX-License-Identifier: Apache-2.0
# set_default_values.rb
# Logstash Ruby script that accepts an array of fields and sets their value if not already set.
# @version 1.0.0
#
# Example Logstash Filter:
# ruby {
#   path => "/etc/logstash/filter_scripts/set_default_values.rb"
#   script_params => {
#     "fields" => [ "[labels][source]", "[labels][instance]" ]
#     "value" => "unknown"
#   }
# }
#
# The above filter configuration would affect an event like so:
#
# Event In -> {
#   "labels": {
#     "foo": "bar",
#     "source": "baz"
#   },
#   "host": "hostname1001"
# }
#
# Event Out -> {
#   "labels": {
#     "foo": "bar",
#     "source": "baz",
#     "instance": "unknown"
#   }
#   "host": "hostname1001"
# }

def register(params)
  @fields = params["fields"] || []
  @value = params["value"]
end

def filter(event)
  unless @value.nil? # skip if no value provided
    @fields.each do |field|
      v = event.get(field)

      if v.nil?
        event.set(field, @value)
        next
      end

      if v.empty?
        event.set(field, @value)
        next
      end
    end
  end
  [event]
end
