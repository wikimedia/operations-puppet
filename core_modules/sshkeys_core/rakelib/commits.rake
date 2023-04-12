desc "verify that commit messages match CONTRIBUTING.md requirements"
task(:commits) do
  # This rake task looks at the summary from every commit from this branch not
  # in the branch targeted for a PR.
  commit_range = 'HEAD^..HEAD'
  puts "Checking commits #{commit_range}"
  %x{git log --no-merges --pretty=%s #{commit_range}}.each_line do |commit_summary|
    # This regex tests for the currently supported commit summary tokens.
    # The exception tries to explain it in more full.
    if /^Release prep|\((maint|packaging|doc|docs|modules-\d+)\)|revert/i.match(commit_summary).nil?
      raise "\n\n\n\tThis commit summary didn't match CONTRIBUTING.md guidelines:\n" \
        "\n\t\t#{commit_summary}\n" \
        "\tThe commit summary (i.e. the first line of the commit message) should start with one of:\n"  \
        "\t\t(MODULES-<digits>) # this is most common and should be a ticket at tickets.puppet.com\n" \
        "\t\t(docs)\n" \
        "\t\t(docs)(DOCUMENT-<digits>)\n" \
        "\t\t(packaging)\n"
        "\t\t(maint)\n" \
        "\t\tRelease prep v<tag>\n" \
        "\n\tThis test for the commit summary is case-insensitive.\n\n\n"
    else
      puts "#{commit_summary}"
    end
    puts "...passed"
  end
end
