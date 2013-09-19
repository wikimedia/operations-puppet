class role::labs::bastion {
    system_role { "role::labs::bastion":
        description => "General role for bastions on Wikimedia Labs"
    }

   class { 'ssh::bastion': }
}
