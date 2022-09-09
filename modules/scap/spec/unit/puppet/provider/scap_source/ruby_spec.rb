# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../../../../rake_modules/spec_helper'

# provider_class = Puppet::Type.type(:scap_source).provider(:default)

describe Puppet::Type.type(:scap_source).provider(:default) do
  let :resource do
    Puppet::Type::Scap_source.new(name: 'somename')
  end
  let :provider do
    Puppet::Type.type(:scap_source).provider(:default).new(resource)
  end

  context 'Origin is Gerrit' do
    let(:params) { { :origin => 'gerrit' } }
    it 'Crafts a canonical repository url' do
      expect(provider.origin('namespace/path/repo')).to eq(
        'https://gerrit.wikimedia.org/r/namespace/path/repo.git'
      )
    end
    it 'Extracts Repository name canonical repository URL' do
      origin = 'https://gerrit.wikimedia.org/r/namespace/path/repo'
      expect(provider.repo_name(origin)).to eq('namespace/path/repo')
    end
    it 'Extracts repository name from legacy URL having /p/' do
      origin = 'https://gerrit.wikimedia.org/r/p/namespace/path/repo'
      expect(provider.repo_name(origin)).to eq('namespace/path/repo')
    end
  end
end
