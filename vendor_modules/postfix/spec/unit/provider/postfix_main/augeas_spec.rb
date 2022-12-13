require 'spec_helper'

provider_class = Puppet::Type.type(:postfix_main).provider(:augeas)

describe provider_class do
  before :each do
    Puppet::Type.type(:postfix_main).stubs(:defaultprovider).returns described_class
    FileTest.stubs(:exist?).returns false
    FileTest.stubs(:exist?).with('/etc/postfix/main.cf').returns true
  end

  context 'with empty file' do
    let(:tmptarget) { aug_fixture('empty') }
    let(:target) { tmptarget.path }

    it 'creates a simple new entry' do
      apply!(Puppet::Type.type(:postfix_main).new(
               name:     'inet_interfaces',
               setting:  'inet_interfaces',
               value:    'localhost',
               target:   target,
               provider: 'augeas',
             ))

      aug_open(target, 'Postfix_Main.lns') do |aug|
        expect(aug.get('inet_interfaces')).to eq('localhost')
      end
    end
  end

  context 'with full file' do
    let(:tmptarget) { aug_fixture('full') }
    let(:target) { tmptarget.path }

    it 'lists instances' do
      provider_class.stubs(:target).returns(target)
      inst = provider_class.instances.map do |p|
        {
          name:    p.get(:name),
          ensure:  p.get(:ensure),
          setting: p.get(:setting),
          value:   p.get(:value),
        }
      end

      expect(inst.size).to eq(21)
      expect(inst[0]).to eq(name: 'queue_directory', ensure: :present, setting: 'queue_directory', value: '/var/spool/postfix')
    end

    describe 'when deleting settings' do
      it 'deletes a setting' do
        expr = 'inet_interfaces'
        aug_open(target, 'Postfix_Main.lns') do |aug|
          expect(aug.match(expr)).not_to eq([])
        end

        apply!(Puppet::Type.type(:postfix_main).new(
                 name:     'inet_interfaces',
                 ensure:   'absent',
                 target:   target,
                 provider: 'augeas',
               ))

        aug_open(target, 'Postfix_Main.lns') do |aug|
          expect(aug.match(expr)).to eq([])
        end
      end
    end
  end
end
