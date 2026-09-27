# frozen_string_literal: true

require 'spec_helper'

describe 'lvm::size_to_bytes' do
  context 'with incorrect parameters' do
    it 'fails' do
      expect(subject).to run.with_params('foo').and_raise_error(
        Puppet::PreformattedError,
        %r{foo is not a valid LVM size},
      )
    end
  end

  context 'with lower case parameters' do
    it 'returns the correct values' do # rubocop:disable RSpec/MultipleExpectations
      expect(subject).to run.with_params('1k').and_return(1024)
      expect(subject).to run.with_params('1m').and_return(1_048_576)
      expect(subject).to run.with_params('1g').and_return(1_073_741_824)
      expect(subject).to run.with_params('1t').and_return(1_099_511_627_776)
      expect(subject).to run.with_params('1.0p').and_return(1.12589991e15)
      expect(subject).to run.with_params('1.0e').and_return(1.1529215e18)
      expect(subject).to run.with_params('200.0g').and_return(214_748_364_800.0)
      expect(subject).to run.with_params('1.5k').and_return(1536.0)
    end
  end
end
