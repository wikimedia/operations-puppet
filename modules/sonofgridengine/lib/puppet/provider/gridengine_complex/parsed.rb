# Copyright 2015 Tim Landscheidt
#
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
require 'wmcs/gridengine_complex_filetype'

Puppet::Type.type(:gridengine_complex).provide(:parsed, :parent => Puppet::Provider::ParsedFile, :default_target => 'default') do
  desc 'Provider for gridengine_complex.'

  commands :qconf => 'qconf'

  def self.filetype
    Puppet::Util::FileType.filetype(:gridengine_complex)
  end

  text_line :comment, :match => /^#/
  text_line :blank, :match => /^\s*$/

  record_line :parsed, :fields => %w{name shortcut type relop requestable consumable default urgency}
end
