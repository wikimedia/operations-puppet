# frozen_string_literal: true

require 'spec_helper'

describe 'volume_groups fact' do
  before :each do
    Facter.clear
  end

  context 'when not on Linux' do
    it 'is set to nil' do
      Facter.fact(:kernel).expects(:value).at_least(1).returns('SunOs')
      Facter.value(:volume_groups).should be_nil
    end
  end

  context 'when on Linux' do
    before :each do
      Facter.fact(:kernel).expects(:value).at_least(1).returns('Linux')
    end

    context 'when vgs is absent' do
      before :each do
        Facter::Core::Execution.stubs('exec') # All other calls
        Facter::Core::Execution.expects('which').with('vgs').at_least(1).returns(nil)
      end

      it 'is set to nil' do
        Facter.value(:volume_groups).should be_nil
      end
    end

    context 'when vgs is present' do
      before :each do
        Facter::Core::Execution.stubs('exec') # All other calls
        Facter::Core::Execution.expects('which').with('vgs').returns('/sbin/vgs')
      end

      it 'is able to resolve vgs' do
        vgs_output = <<-OUTPUT
          ZcFkEG-217a-nnc6-PvWx-oXou-7THt-XR6eci centos wz--n- writeable  normal     19.51g 44.00m
          tMqdQC-ukEx-bEft-bLk8-WoM1-jX0a-0p1rri tasks  wz--n- writeable  normal      3.99g  2.82g
        OUTPUT
        vgs_output.dup.lstrip!
        Facter::Core::Execution.expects(:exec).at_least(1).returns(vgs_output)
        Facter.value(:volume_groups).should include('centos' => {
                                                      'uuid' => 'ZcFkEG-217a-nnc6-PvWx-oXou-7THt-XR6eci',
                                                      'attr' => 'wz--n-', 'permissions' => 'writeable',
                                                      'allocation_policy' => 'normal',
                                                      'size' => '19.51g',
                                                      'free' => '44.00m'
                                                    },
                                                    'tasks' => {
                                                      'uuid' => 'tMqdQC-ukEx-bEft-bLk8-WoM1-jX0a-0p1rri',
                                                      'attr' => 'wz--n-',
                                                      'permissions' => 'writeable',
                                                      'allocation_policy' => 'normal',
                                                      'size' => '3.99g',
                                                      'free' => '2.82g'
                                                    })
      end
    end
  end
end
