# frozen_string_literal: true

require 'rspec'
require 'spec_helper'

ENV['LVM_SKIP_ACCEPTANCE_SETUP'] = 'true'
require_relative '../spec_helper_acceptance_local'

describe 'spec_helper_acceptance_local cleanup methods' do
  def status(success)
    stub(success?: success)
  end

  it 'retries local gcloud command on connection reset and then succeeds' do
    capture3 = stub
    capture3.expects(:call).with('gcloud cmd').twice.returns(
      ['', 'Connection reset by peer', status(false)],
      ['', '', status(true)],
    )

    sleeper = stub
    sleeper.expects(:call).with(1).once

    warning = stub
    warning.expects(:call).never

    result = run_local_gcloud_with_retry('gcloud cmd', retries: 1, delay: 1, capture3:, sleeper:, warning:)
    expect(result).to eq(:done)
  end

  it 'returns auth_error when local gcloud auth is missing' do
    capture3 = stub
    capture3.expects(:call).with('gcloud cmd').returns(['', 'You do not currently have an active account selected.', status(false)]).once

    warning = stub
    warning.expects(:call).never

    result = run_local_gcloud_with_retry('gcloud cmd', capture3:, warning:)
    expect(result).to eq(:auth_error)
  end

  it 'falls back to remote retry when local auth is missing' do
    command = 'gcloud compute disks delete test --zone=us-west1-c --quiet'

    expects(:run_local_gcloud_with_retry).with(command).returns(:auth_error)
    expects(:run_remote_shell_with_retry).with(command)

    run_gcloud_cleanup_command(command)
  end

  it 'does not call remote cleanup when local cleanup succeeds' do
    command = 'gcloud compute disks delete test --zone=us-west1-c --quiet'

    expects(:run_local_gcloud_with_retry).with(command).returns(:done)
    expects(:run_remote_shell_with_retry).never

    run_gcloud_cleanup_command(command)
  end
end
