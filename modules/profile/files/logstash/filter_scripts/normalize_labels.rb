# SPDX-License-Identifier: Apache-2.0
# normalize_labels.rb
# Logstash Ruby script to cast the type of all labels to string
# @version 1.0.0

def register(*) end

def filter(event)
  original_labels = event.get('labels')

  # nothing to do if labels is not a hash
  return [event] unless original_labels.instance_of? Hash

  # cast all labels to string
  original_labels.each do | key, value |
    event.set("[labels][#{key}]", value.to_s)
  end

  [event]
end
