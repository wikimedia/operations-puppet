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

Puppet::Type.newtype(:gridengine_config) do
  desc <<-'ENDOFDESC'
  Resource type to manage gridengine global configurations.

  The resources are mapped directly to the corresponding gridengine
  configurations.  Cf. sge_conf(5) for the specification and
  implications.

  ENDOFDESC

  ensurable

  newparam(:name) do
    desc "The name of the configuration."
  end

  newproperty(:value) do
    desc "The value of the configuration."
  end
end
