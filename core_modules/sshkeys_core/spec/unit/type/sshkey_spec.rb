require 'spec_helper'
require 'pry'

describe Puppet::Type.type(:sshkey) do
  it 'uses :name and :type as its namevar' do
    expect(described_class.key_attributes).to eq [:type, :name]
  end

  describe 'when validating attributes' do
    [:name, :provider, :type].each do |param|
      it "has a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq :param
      end
    end

    [:host_aliases, :ensure, :key].each do |property|
      it "has a #{property} property" do
        expect(described_class.attrtype(property)).to eq :property
      end
    end
  end

  describe 'when validating values' do
    [
      :'ssh-dss', :dsa,
      :'ssh-rsa', :rsa,
      :'ecdsa-sha2-nistp256',
      :'ecdsa-sha2-nistp384',
      :'ecdsa-sha2-nistp521',
      :'ssh-ed25519', :ed25519,
      :'ecdsa-sk', :'sk-ecdsa-sha2-nistp256@openssh.com',
      :'ed25519-sk', :'sk-ssh-ed25519@openssh.com'
    ].each do |keytype|
      it "supports #{keytype} as a type value" do
        described_class.new(name: 'foo', type: keytype)
      end
    end

    it 'aliases :rsa to :ssh-rsa' do
      key = described_class.new(name: 'foo', type: :rsa)
      expect(key.parameter(:type).value).to eq :'ssh-rsa'
    end

    it 'aliases :dsa to :ssh-dss' do
      key = described_class.new(name: 'foo', type: :dsa)
      expect(key.parameter(:type).value).to eq :'ssh-dss'
    end

    it 'aliases :ecdsa-sk to :sk-ecdsa-sha2-nistp256@openssh.com' do
      key = described_class.new(name: 'foo', type: :'ecdsa-sk')
      expect(key.parameter(:type).value).to eq :'sk-ecdsa-sha2-nistp256@openssh.com'
    end

    it 'aliases :ed25519-sk to :ssh-dss' do
      key = described_class.new(name: 'foo', type: :'ed25519-sk')
      expect(key.parameter(:type).value).to eq :'sk-ssh-ed25519@openssh.com'
    end

    it "doesn't support values other than ssh-dss, ssh-rsa, dsa, rsa for type" do
      expect {
        described_class.new(name: 'whev', type: :'ssh-dsa')
      }.to raise_error(Puppet::Error, %r{Invalid value.*ssh-dsa})
    end

    it 'accepts one host_alias' do
      described_class.new(name: 'foo', host_aliases: 'foo.bar.tld')
    end

    it 'accepts multiple host_aliases as an array' do
      described_class.new(name: 'foo', host_aliases: ['foo.bar.tld', '10.0.9.9'])
    end

    it "doesn't accept spaces in any host_alias" do
      expect {
        described_class.new(name: 'foo', host_aliases: ['foo.bar.tld', 'foo bar'])
      }.to raise_error(Puppet::Error, %r{cannot include whitespace})
    end

    it "doesn't accept aliases in the resourcename" do
      expect {
        described_class.new(name: 'host,host.domain,ip')
      }.to raise_error(Puppet::Error, %r{No comma in resourcename})
    end

    it 'aliases :title to :name' do
      key = described_class.new(name: 'foo', type: :rsa)
      expect(key.name).to eq key.title
    end
  end
end
