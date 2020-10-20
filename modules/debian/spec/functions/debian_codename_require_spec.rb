require 'spec_helper'
require 'pp'

describe 'debian::codename::require' do
  on_supported_os(supported_os: ['operatingsystem' => 'Debian', 'operatingsystemrelease' => ['10']]).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      it { is_expected.to run.with_params('buster').and_return(nil) }
      it { is_expected.to run.with_params('stretch').and_raise_error(/node codename does not meet requirement/) }
      it { is_expected.to run.with_params('buster', '>=').and_return(nil) }
      it { is_expected.to run.with_params('buster', '<=').and_return(nil) }
      it { is_expected.to run.with_params('buster', '>').and_raise_error(/node codename does not meet requirement/) }
      it { is_expected.to run.with_params('stretch', '>').and_return(nil) }
      it { is_expected.to run.with_params('buster', '<').and_raise_error(/node codename does not meet requirement/) }
      it { is_expected.to run.with_params('bullseye', '<').and_return(nil) }
      it { is_expected.to run.with_params('buster', '!=').and_raise_error(/node codename does not meet requirement/) }
      it { is_expected.to run.with_params('jessie', '!=').and_return(nil) }
    end
  end
end
