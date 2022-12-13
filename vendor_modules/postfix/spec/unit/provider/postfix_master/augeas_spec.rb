require 'spec_helper'

provider_class = Puppet::Type.type(:postfix_master).provider(:augeas)

describe provider_class do
  before :each do
    Puppet::Type.type(:postfix_master).stubs(:defaultprovider).returns described_class
    FileTest.stubs(:exist?).returns false
    FileTest.stubs(:exist?).with('/etc/postfix/master.cf').returns true
  end

  context 'with empty file' do
    let(:tmptarget) { aug_fixture('empty') }
    let(:target) { tmptarget.path }

    it 'creates a simple new entry' do
      apply!(Puppet::Type.type(:postfix_master).new(
               name:         'test',
               service:      'submission',
               type:         'inet',
               private:      'n',
               unprivileged: '-',
               chroot:       'n',
               wakeup:       '-',
               limit:        '-',
               command:      'smtpd',
               target:       target,
               provider:     'augeas',
             ))

      aug_open(target, 'Postfix_Master.lns') do |aug|
        expect(aug.get("submission[type = 'inet']/command")).to eq('smtpd')
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
          name:         p.get(:name),
          ensure:       p.get(:ensure),
          service:      p.get(:service),
          type:         p.get(:type),
          private:      p.get(:private),
          unprivileged: p.get(:unprivileged),
          chroot:       p.get(:chroot),
          wakeup:       p.get(:wakeup),
          limit:        p.get(:limit),
          command:      p.get(:command),
        }
      end

      expect(inst.size).to eq(24)
      expect(inst[0]).to eq(name: 'smtp/inet', ensure: :present, service: 'smtp', type: 'inet', private: 'n', unprivileged: '-', chroot: 'n', wakeup: '-', limit: '-', command: 'smtpd')
    end

    describe 'when deleting settings' do
      it 'deletes a setting' do
        expr = "smtp[type = 'inet']"
        aug_open(target, 'Postfix_Master.lns') do |aug|
          expect(aug.match(expr)).not_to eq([])
        end

        apply!(Puppet::Type.type(:postfix_master).new(
                 name:     'smtp/inet',
                 ensure:   'absent',
                 target:   target,
                 provider: 'augeas',
               ))

        aug_open(target, 'Postfix_Master.lns') do |aug|
          expect(aug.match(expr)).to eq([])
        end
      end
    end
  end
end
