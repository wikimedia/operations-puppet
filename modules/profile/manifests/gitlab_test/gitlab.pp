# == Class profile::gitlab_test::gitlab
#
# Allow git to login.
#
# GitLab uses the default sshd server on the host machine to manage
# ssh access. It creates a command in the authorized_keys file in the git
# user's home directory.
#
# filtertags: labs-project-gitlab-test
class profile::gitlab_test::gitlab {
    security::access::config { 'gitlab-allow-git':
        content  => "+ : git : ALL\n",
        priority => 60,
    }
}
