# Copyright 2015 Tim Landscheidt and Brooke Storm
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

Puppet::Type.newtype(:gridengine_complex) do
  desc <<-'ENDOFDESC'
  Resource type to manage gridengine complexes.

  The attributes are mapped directly to the corresponding gridengine
  fields.  Cf. sge_complex(5) for the specification and implications.

  For new complexes, all attributes need to be given.

  ENDOFDESC

  ensurable

  newparam(:name) do
    desc "The name of the complex."
  end

  newproperty(:shortcut) do
    desc "The shortcut name of the complex."
  end

  newproperty(:type) do
    desc "The type of the complex."
  end

  newproperty(:relop) do
    desc "The relation operator of the complex."
  end

  newproperty(:requestable) do
    desc "Whether the complex is requestable."
  end

  newproperty(:consumable) do
    desc "Whether the complex is consumable."
  end

  newproperty(:default) do
    desc "The default value of the complex."
  end

  newproperty(:urgency) do
    desc "The urgency value of the complex."
  end
end
