require 'spec_helper_acceptance'

RSpec.context 'sshkeys: Purge' do
  let(:keyname) { "pl#{rand(999_999).to_i}" }

  # FIXME: This is bletcherous
  let(:ssh_known_hosts) { '/etc/ssh/ssh_known_hosts' }

  let(:purge_manifest) do
    <<-MANIFEST
    resources { 'sshkey':
      purge => true,
    }
    MANIFEST
  end

  before(:each) do
    posix_agents.agents.each do |agent|
      # The 'cp' might fail because the source file doesn't exist
      on(
        agent,
        "cp -fv #{ssh_known_hosts} /tmp/ssh_known_hosts",
        acceptable_exit_codes: [0, 1],
      )
      cmd = <<-CMD
echo '' > #{ssh_known_hosts}
echo '#{keyname} ssh-rsa how_about_the_initial_rsa_key_of_c' >> #{ssh_known_hosts}
echo '#{keyname} ssh-dss how_about_the_initial_dss_key_of_c' >> #{ssh_known_hosts}
CMD
      on(agent, cmd)
    end
  end

  after(:each) do
    posix_agents.each do |agent|
      # Is it present?
      rc = on(
        agent,
        '[ -e /tmp/ssh_known_hosts ]',
        accept_all_exit_codes: true,
      )
      if rc.exit_code == 0
        # It's present, so restore the original
        on(
          agent,
          "mv -fv /tmp/ssh_known_hosts #{ssh_known_hosts}",
          accept_all_exit_codes: true,
        )
      else
        # It's missing, which means there wasn't one to backup; just
        # delete the one we laid down
        on(
          agent,
          "rm -fv #{ssh_known_hosts}",
          accept_all_exit_codes: true,
        )
      end
    end
  end

  posix_agents.each do |agent|
    it "#{agent} should be able to purge all SSH known host keys" do
      apply_manifest_on(agent, purge_manifest, catch_failures: true)

      # expect purging to be idempotent
      apply_manifest_on(agent, purge_manifest, catch_changes: true)

      on(agent, "cat #{ssh_known_hosts}") do |_res|
        expect(stdout).not_to include('how_about_the_initial')
      end
    end
  end
end
