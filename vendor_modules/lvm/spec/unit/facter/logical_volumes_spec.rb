# frozen_string_literal: true

require 'spec_helper'

describe 'logical_volumes fact' do
  before :each do
    Facter.clear
  end

  context 'when not on Linux' do
    it 'is set to nil' do
      Facter.fact(:kernel).expects(:value).at_least(1).returns('SunOs')
      Facter.value(:logical_volumes).should be_nil
    end
  end

  context 'when on Linux' do
    before :each do
      Facter.fact(:kernel).expects(:value).at_least(1).returns('Linux')
    end

    context 'when lvs is absent' do
      before :each do
        Facter::Core::Execution.stubs('exec') # All other calls
        Facter::Core::Execution.expects('which').with('lvs').at_least(1).returns(nil)
      end

      it 'is set to nil' do
        Facter.value(:logical_volumes).should be_nil
      end
    end

    context 'when lvs is present' do
      before :each do
        Facter::Core::Execution.stubs('exec') # All other calls
        Facter::Core::Execution.expects('which').with('lvs').returns('/sbin/lvs')
      end

      it 'is able to resolve VGs' do
        lvs_output = <<-OUTPUT
        E7qan8-4NGf-jq2P-l11v-6fFe-MPHK-T6IGzl root       centos/root      /dev/centos/root      /dev/mapper/centos-root      -wi-ao---- linear     public     active  18.46g writeable
        buUXDX-GDUh-rN2t-y80n-vtCt-xhhu-XSZ5kA swap       centos/swap      /dev/centos/swap      /dev/mapper/centos-swap      -wi-ao---- linear     public     active   1.00g writeable
        uedsry-OTVv-wGW4-vaFf-c7IY-oH6Z-ig6IXB cool_tasks tasks/cool_tasks /dev/tasks/cool_tasks /dev/mapper/tasks-cool_tasks -wi-a----- linear     public     active 800.00m writeable
        gmNS3G-cAhA-vRj0-2Uf0-21yO-QVdy-LNXfBv lame_tasks tasks/lame_tasks /dev/tasks/lame_tasks /dev/mapper/tasks-lame_tasks -wi-a----- linear     public     active 400.00m writeable
        OUTPUT
        lvs_output.dup.lstrip!
        Facter::Core::Execution.expects(:exec).at_least(1).returns(lvs_output)
        Facter.value(:logical_volumes).should include('cool_tasks' => {
                                                        'uuid' => 'uedsry-OTVv-wGW4-vaFf-c7IY-oH6Z-ig6IXB',
                                                        'full_name' => 'tasks/cool_tasks',
                                                        'path' => '/dev/tasks/cool_tasks',
                                                        'dm_path' => '/dev/mapper/tasks-cool_tasks',
                                                        'attr' => '-wi-a-----',
                                                        'layout' => 'linear',
                                                        'role' => 'public',
                                                        'active' => 'active',
                                                        'size' => '800.00m',
                                                        'permissions' => 'writeable'
                                                      },
                                                      'lame_tasks' => {
                                                        'uuid' => 'gmNS3G-cAhA-vRj0-2Uf0-21yO-QVdy-LNXfBv',
                                                        'full_name' => 'tasks/lame_tasks',
                                                        'path' => '/dev/tasks/lame_tasks',
                                                        'dm_path' => '/dev/mapper/tasks-lame_tasks',
                                                        'attr' => '-wi-a-----',
                                                        'layout' => 'linear',
                                                        'role' => 'public',
                                                        'active' => 'active',
                                                        'size' => '400.00m',
                                                        'permissions' => 'writeable'
                                                      },
                                                      'root' => {
                                                        'uuid' => 'E7qan8-4NGf-jq2P-l11v-6fFe-MPHK-T6IGzl',
                                                        'full_name' => 'centos/root',
                                                        'path' => '/dev/centos/root',
                                                        'dm_path' => '/dev/mapper/centos-root',
                                                        'attr' => '-wi-ao----',
                                                        'layout' => 'linear',
                                                        'role' => 'public',
                                                        'active' => 'active',
                                                        'size' => '18.46g',
                                                        'permissions' => 'writeable'
                                                      },
                                                      'swap' => {
                                                        'uuid' => 'buUXDX-GDUh-rN2t-y80n-vtCt-xhhu-XSZ5kA',
                                                        'full_name' => 'centos/swap',
                                                        'path' => '/dev/centos/swap',
                                                        'dm_path' => '/dev/mapper/centos-swap',
                                                        'attr' => '-wi-ao----',
                                                        'layout' => 'linear',
                                                        'role' => 'public',
                                                        'active' => 'active',
                                                        'size' => '1.00g',
                                                        'permissions' => 'writeable'
                                                      })
      end
    end
  end
end
