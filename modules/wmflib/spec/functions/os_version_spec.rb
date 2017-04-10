require 'spec_helper'

describe 'os_version' do

  it 'should be defined' do
    expect(subject).to_not be_nil
  end

  context 'when invoked with no arguments' do
    it 'raises an error' do
      expect(subject).to run.with_params.and_raise_error(ArgumentError)
    end
  end

  context 'when running on Ubuntu Trusty 14.04' do
    let(:facts) do
      {
        :lsbdistrelease => '14.04',
        :lsbdistid => 'Ubuntu',
      }
    end

    it 'matches properly' do
      expect(subject).to run.with_params('Ubuntu == trusty').and_return(true)
      expect(subject).to run.with_params('Ubuntu >= trusty').and_return(true)
      expect(subject).to run.with_params('Ubuntu <= trusty').and_return(true)
      expect(subject).to run.with_params('Ubuntu > trusty').and_return(false)
      expect(subject).to run.with_params('Ubuntu < trusty').and_return(false)
    end
  end

  context 'when running on Debian Jessie 8' do
    let(:facts) do
      {
        :lsbdistrelease => '8.7',
        :lsbdistid => 'Debian',
      }
    end

    it 'matches comparing current release' do
      expect(subject).to run.with_params('Debian == jessie').and_return(true)
      expect(subject).to run.with_params('Debian >= jessie').and_return(true)
      expect(subject).to run.with_params('Debian <= jessie').and_return(true)
      expect(subject).to run.with_params('Debian > jessie').and_return(false)
      expect(subject).to run.with_params('Debian < jessie').and_return(false)
    end

    it 'matches comparing with next release' do
      expect(subject).to run.with_params('Debian == stretch').and_return(false)
      expect(subject).to run.with_params('Debian >= stretch').and_return(false)
      expect(subject).to run.with_params('Debian <= stretch').and_return(true)
      expect(subject).to run.with_params('Debian > stretch').and_return(false)
      expect(subject).to run.with_params('Debian < stretch').and_return(true)
    end
  end

end
