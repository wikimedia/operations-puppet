require 'spec_helper'

describe Puppet::Type.type(:postfix_master) do
  it 'has :name, :service & :type as its keyattributes' do
    expect(described_class.key_attributes).to eq([:name, :service, :type])
  end

  describe 'when validating attributes' do
    [:name, :service, :type, :target].each do |param|
      it "has a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:ensure, :private, :unprivileged, :chroot, :wakeup, :limit, :command].each do |property|
      it "has a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'autorequire' do
    let(:catalog) do
      Puppet::Resource::Catalog.new
    end

    it 'autorequires the targeted file' do
      file = Puppet::Type.type(:file).new(name: '/etc/postfix/master.cf')
      catalog.add_resource file
      key = described_class.new(name: 'submission/inet', target: '/etc/postfix/master.cf', command: 'smtpd', ensure: :present)
      catalog.add_resource key
      expect(key.autorequire.size).to eq(1)
    end
    it 'autorequires the setting' do
      postfix_main = Puppet::Type.type(:postfix_main).new(name: 'submission_mumble')
      catalog.add_resource postfix_main
      key = described_class.new(name: 'submission/inet', command: 'smtpd -o smtpd_mumble=$submission_mumble', ensure: :present)
      catalog.add_resource key
      expect(key.autorequire.size).to eq(1)
    end
    it 'autorequires the service' do
      service = Puppet::Type.type(:postfix_master).new(name: 'bounce/unix')
      catalog.add_resource service
      key = described_class.new(name: 'submission/inet', command: 'smtpd -o bounce_service_name=bounce', ensure: :present)
      catalog.add_resource key
      expect(key.autorequire.size).to eq(1)
    end
    it 'autorequires the user and group' do
      user = Puppet::Type.type(:user).new(name: 'vmail')
      catalog.add_resource user
      group = Puppet::Type.type(:group).new(name: 'vmail')
      catalog.add_resource group
      key = described_class.new(name: 'dovecot/unix', command: 'pipe user=vmail:vmail argv=/path/to/dovecot-lda', ensure: :present)
      catalog.add_resource key
      expect(key.autorequire.size).to eq(2)
    end
  end
end
