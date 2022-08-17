# nest_root_fields.rb
# Logstash Ruby script to copy all root fields into sub-fields of an object
# @version 1.0.1
#
# Example Logstash Filter:
# ruby {
#   path => "/etc/logstash/filter_scripts/nest_root_fields.rb"
#   script_params => {
#     "exclude" => [ "c" ]
#     "exclude_common_fields" => true
#     "target" => "labels"
#     "overwrite" => true
#   }
# }
#
# The above filter configuration would affect an event like so:
#
# Event In -> {
#   "labels": "overwrite me",
#   "a": "field a",
#   "b": "field b",
#   "c": "field c",
#   "host": "hostname1001"
# }
#
# Event Out -> {
#   "labels": {
#     "a": "field a",
#     "b": "field b"
#   }
#   "host": "hostname1001",
#   "c": "field c"
# }

def register(params)
  @exclude = params["exclude"] || []
  @target = params["target"]
  @overwrite = params["overwrite"]
  @exclude_common_fields = params["exclude_common_fields"]
  @common_fields = %w[
    logsource
    type
    host
    timestamp
    program
    message
    facility
    level
    path
    severity
    rsyslog.facility
    rsyslog.hostname
    rsyslog.programname
    rsyslog.severity
    rsyslog.timereported
  ]
end

# get the event with an additional tag
def event_with_tag(event, value)
  tags = event.get("tags")
  tags.push(value)
  event.set("tags", tags)
  event
end

def filter(event)
  unless @target.nil? # skip if no target provided

    target_field_values = event.get(@target)
    result = {}

    if target_field_values.instance_of?(Hash) # if target is a hash, we can use it as-is
      result = target_field_values.to_hash
    else # if target exists and is not hashable, do nothing else but add a tag so we know it happened
      return [event_with_tag(event, '_nest_root_fields_unhashable_target_field')] unless @overwrite
    end

    @exclude += @common_fields if @exclude_common_fields

    event.to_hash.each_key do |k|
      next if k[0] == "@" # skip meta fields
      next if k == "tags" # skip tags
      next if @exclude.include?(k) # skip excluded fields
      result[k] = event.get(k)
      event.remove(k)
    end

    event.set(@target, result)

  end
  [event]
end
