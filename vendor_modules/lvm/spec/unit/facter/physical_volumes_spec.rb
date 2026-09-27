# frozen_string_literal: true

require 'spec_helper'

describe 'physical_volumes fact' do
  before :each do
    Facter.clear
  end

  context 'when not on Linux' do
    it 'is set to nil' do
      Facter.fact(:kernel).expects(:value).at_least(1).returns('SunOs')
      Facter.value(:physical_volumes).should be_nil
    end
  end

  context 'when on Linux' do
    before :each do
      Facter.fact(:kernel).expects(:value).at_least(1).returns('Linux')
    end

    context 'when pvs is absent' do
      before :each do
        Facter::Core::Execution.stubs('exec') # All other calls
        Facter::Core::Execution.expects('which').with('pvs').at_least(1).returns(nil)
      end

      it 'is set to nil' do
        Facter.value(:physical_volumes).should be_nil
      end
    end

    context 'when pvs is present' do
      before :each do
        Facter::Core::Execution.stubs('exec') # All other calls
        Facter::Core::Execution.expects('which').with('pvs').returns('/sbin/pvs')
      end

      it 'is able to resolve PVs' do
        pvs_output = <<-OUTPUT
          dPziSO-573Z-9WuH-q22X-cuyM-gHQx-ZeGbfK   2.00g /dev/sda     1.00m  2.00g 844.00m  1.17g a--   511   300     1        1        0       0
          09ksGm-Pt28-AR9H-NlgQ-QxtG-5uEH-Qzy1RR   2.00g /dev/sdc     1.00m  2.00g   2.00g      0 a--   511     0     1        1        0       0
          PpSFVZ-SS3P-n3a6-ctPF-sb9H-6M85-i0TqBv  19.51g /dev/sdd2    1.00m 19.51g  44.00m 19.46g a--  4994  4983     1        1        0       0
        OUTPUT
        pvs_output.dup.lstrip!
        Facter::Core::Execution.expects(:exec).at_least(1).returns(pvs_output)
        Facter.value(:physical_volumes).should include('/dev/sda' => {
                                                         'uuid' => 'dPziSO-573Z-9WuH-q22X-cuyM-gHQx-ZeGbfK',
                                                         'size' => '2.00g',
                                                         'start' => '1.00m',
                                                         'free' => '844.00m',
                                                         'used' => '1.17g',
                                                         'attr' => 'a--',
                                                         'pe_count' => '511',
                                                         'pe_alloc_count' => '300',
                                                         'mda_count' => '1',
                                                         'mda_used_count' => '1',
                                                         'ba_start' => '0',
                                                         'ba_size' => '0'
                                                       },
                                                       '/dev/sdc' => {
                                                         'uuid' => '09ksGm-Pt28-AR9H-NlgQ-QxtG-5uEH-Qzy1RR',
                                                         'size' => '2.00g',
                                                         'start' => '1.00m',
                                                         'free' => '2.00g',
                                                         'used' => '0',
                                                         'attr' => 'a--',
                                                         'pe_count' => '511',
                                                         'pe_alloc_count' => '0',
                                                         'mda_count' => '1',
                                                         'mda_used_count' => '1',
                                                         'ba_start' => '0',
                                                         'ba_size' => '0'
                                                       },
                                                       '/dev/sdd2' => {
                                                         'uuid' => 'PpSFVZ-SS3P-n3a6-ctPF-sb9H-6M85-i0TqBv',
                                                         'size' => '19.51g',
                                                         'start' => '1.00m',
                                                         'free' => '44.00m',
                                                         'used' => '19.46g',
                                                         'attr' => 'a--',
                                                         'pe_count' => '4994',
                                                         'pe_alloc_count' => '4983',
                                                         'mda_count' => '1',
                                                         'mda_used_count' => '1',
                                                         'ba_start' => '0',
                                                         'ba_size' => '0'
                                                       })
      end
    end
  end
end
