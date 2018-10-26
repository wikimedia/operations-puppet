# Copyright 2018 Brooke Storm

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'puppet/provider/parsedfile'
require 'puppet/util/execution'
require 'puppet/util/filetype'
require 'wmcs/gridengine_queue_filetype'

Puppet::Type.type(:gridengine_queue).provide(:parsed, :parent => Puppet::Provider::ParsedFile, :default_target => 'default') do
  desc 'Provider for gridengine_queues.'

  commands :qconf => 'qconf'

  def self.filetype
    Puppet::Util::FileType.filetype(:gridengine_queue)
  end

  text_line :comment, :match => /^#/
  text_line :blank, :match => /^\s*$/

  record_line :parsed, :fields => [
    "hostlist", "seq_no", "load_thresholds", "suspend_thresholds",
    "nsuspend", "suspend_interval", "priority", "min_cpu_interval",
    "processors", "qtype", "pe_list", "ckpt_list", "rerun", "slots",
    "tmpdir", "shell", "prolog", "epliog", "shell_start_mode",
    "starter_method", "suspend_method", "resume_method", "terminate_method",
    "notify", "ownerlist", "userlists", "xuserlists", "subordinate_list",
    "complex_values", "projects", "xprojects", "calendar", "initial_state",
    "s_rt", "h_rt", "s_cpu", "h_cpu", "s_fsize", "h_fsize", "s_data", "h_data",
    "s_stack", "h_stack", "s_core", "h_core", "s_rss", "h_rss", "s_vmem",
    "h_vmem"
  ]
end
