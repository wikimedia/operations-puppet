# Puppet default provider for type `scap_source`, which is needed to set up a
# base repository to use with the `scap3` deployment system
#
# Copyright (c) 2016 Giuseppe Lavagetto
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'puppet/provider/scap_source'

Puppet::Type.type(:scap_source).provide(:default, :parent => Puppet::Provider::Scap_source) do
  desc 'Puppet provider for scap_source, for gerrit projects'

  # The origin of the repository
  def origin(repo_name)
    "https://gerrit.wikimedia.org/r/p/#{repo_name}.git"
  end

  def repo_name(origin)
    origin.gsub('#https://gerrit.wikimedia.org/r/p/#', '').gsub('/\.git$/', '')
  end

end
