require 'spec_helper'
describe 'debian::codename::compare' do
  on_supported_os(supported_os: ['operatingsystem' => 'Debian', 'operatingsystemrelease' => ['10']]).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      it { is_expected.to run.with_params('buster').and_return(true) }
      it { is_expected.to run.with_params('stretch').and_return(false) }
      it { is_expected.to run.with_params('buster', '>=').and_return(true) }
      it { is_expected.to run.with_params('buster', '<=').and_return(true) }
      it { is_expected.to run.with_params('buster', '>').and_return(false) }
      it { is_expected.to run.with_params('stretch', '>').and_return(true) }
      it { is_expected.to run.with_params('buster', '<').and_return(false) }
      it { is_expected.to run.with_params('bullseye', '<').and_return(true) }
      it { is_expected.to run.with_params('buster', '!=').and_return(false) }
      it { is_expected.to run.with_params('jessie', '!=').and_return(true) }
    end
  end
end
