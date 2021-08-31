
This admin module is meant to manage all users, groups, and permissions (sudo).

All managed resources should be defined in yaml.

see: `admin/data/data.yaml`

## Examples

### Adding a group
```yaml
    groups:
      mygroup:
        ensure: present
        gid: 551
        members: [foo, bar]
```

### Managing members for a default system group

-> For groups without a set GID we do not attempt creation
```yaml
    groups:
      adm:
        members: [foo, bar]
```

### Removing a member from a group

Removing `bar` user from mygroup means removal from members array
```yaml
    groups:
      mygroup:
        ensure: present
        gid: 551
        members: [foo, bar] -> members: [foo]
```

### Removing a group

-> absenting a group will remove it where it was applied
```yaml
    groups:
      mygroup:
        foo:
          ensure: absent
          gid: 679
          members: []
```

### Adding user 'foo'

-> Since assignment is group centric this user won't be created anywhere yet
```yaml
    users:
        foo:
          uid: 1146
          gid: 500
          realname: Foo Bar
          ssh_keys: [ssh-rsa mykeyhash foobar@mac]
```

### Ensuring a system user is in a group: (see note below about system user group membership
```yaml
    groups:
      mygroup:
        ensure: present
        gid: 551
        members: [foo, bar]
        system_members: [www-data]
```

## Adding a new human user
To choose the UID for a new user please lookup
the existing UID in (labs) LDAP and use that.
currently you do this on mwmaint1002.
For example, to look up user "someuser":

```
/usr/bin/ldapsearch -x "uid=someuser*"
```

Advantages: no more duplicate UIDs that needed fixing,
matching UID across production and labs,
no need to grep|sort for the latest free UID anymore
almost every user who gets prod. shell already has a
labs user. if not, ask them nicely to make one first

SSH keys added to this file always need to be verified.
acceptable methods of verification include:
gpg signing, having them pasted on office wiki user pages,
having them +1 by logged in gerrit users
unacceptable methods include:
plain email (senders can't be trusted),
IRC (definitely if not registered/identified with nickserv)
RT-only (because it can be emailed)

Add the ''realname'' of the user (most labs accounts don't have a real name set)

Add the ''email'' address of the users:
- If the user is WMF staff use the email address of their Google account
  (usually the first letter of the first name and the surname, you can
  double-check the account name in the Gmail interface). Some users have
  aliases for their nickname e.g., don't use these, use the official Google
  account (this allows cross-checking data against OIT corp LDAP)
- If the user is a volunteer, a researcher or contractor without access to a
  wikimedia.org account, ask for a contact email address (to have a reliable
  contact e.g. in case of an account compromise)

If the user to be added is someone with a time-limited access (e.g. interns,
researchers (who have time-limited MOUs) or short term contractor), add the
estimated account end date as ''expiry_date'' (format is YYYY-MM-DD) and add
a staff contact as ''expiry_contact''


## Adding user `foo` to group `adm`

```yaml
    groups:
        adm:
            members: [foo]
```

## Removing user `foo`

* absented users cannot be members of a group -- other than absent --
* users who are not a member of a supplementary group are removed
* Therefore, removing a user from all groups means they will be removed
   everywhere they existed because of those groups.

```yaml
    groups:
        adm:
          members: [foo, bar] -> members: [bar]
```
User garbage collection logs to syslog and console:

    #manual ensure absent example output
    notice: /Stage[main]/Admin/Admin::Yamluser[foo]/Admin::User[foo]/User[foo]/ensure: removed

    #straggling user cleanup puppet output
    notice: /Stage[main]/Admin/Exec[enforce-users-groups-cleanup]/returns: \
        /usr/local/bin/enforce-users-groups removing user/id: foo/1001

    #straggling user cleanup syslog output
    May  6 10:54:43 uone logger: /usr/local/bin/enforce-users-groups removing user/id: foo/1001

However, if you want to ensure a user is especially missing globally
* Mark the user as 'ensure: absent'
* Add the user to the meta 'absent' group
```yaml
    groups:
      absent:
        members: [foo]

    users:
        foo:
        ensure: absent
        uid: 510
        gid: 500
        realname: Foo Bar
        ssh_keys: [ssh-rsa mykeyhash foobar@mac]
```

`absent` group users:
* are _always_ included in every batch of assignments
* should never have `ensure: present`
* cannot be a member of any other group

## Assigning groups / users


* one 'class admin' assignment per node must be done since we need state information on all assigned users
* `ops` and `absent` groups are always included

```puppet
#create group and assign users
node /myhost/ {
    class { 'admin':
        groups => ['mygroup'],
    }
}
```
or (including managed members of a system group):

```puppet
#this creates both groups, and all relevant users of both groups even with overlap
node /myhost/ {
    class { 'admin':
        groups => ['mygroup', 'adm'],
    }
}

#creates three groups and all relevants users and permissions details
node /myhost/ {
    class { 'admin':
        groups => ['mygroup','adm','foo'],
    }
}
```

## Assigning sudo permissions to a group
```yaml
    groups:
        adm:
        members: [foo, bar]
        privileges: [ALL=(ALL:ALL) ALL]
```
Creates: '/etc/sudoers.d/adm'

        # This file is managed by Puppet!
        %adm ALL=(ALL:ALL) ALL

Users can be given sudo permissions in the same way:

* this is a limited use approach.  these permissions would apply across the entire env.
```yaml
  foo:
    ensure: present
    privileges: [ALL=(ALL:ALL) ALL]
```

## Getting your /home/ stuff wherever you are

If you define a dir for your username in `${module}/files/home` all contents are managed
```
    ├── files
    │   ├── home
    │   │   ├── foo
    │   │   │   └── .vimrc
```

Notes:
* Individual /home data is intended to live somewhere other than our Puppet repo once
  figure out where it should live permanently
* Groups with no members get root by default
* admin::user and admin::group are not dependent on yaml

## Renaming Users

https://wikitech.wikimedia.org/wiki/Ops_Clinic_Duty#Renaming_shell_users

Sometimes we have to rename a shell user.  This is typically when their shell name doesn't
match their login name, and they have issues logging into items requiring LDAP credentials

Private data that isn't allowed to be copied off the cluster should not be backed up to
laptops.  So we need to move user home data for the user.

* Patchset is prepared, but not merged.
* All affected hosts have puppet halted.
* Affected hosts should have the user (to be replaced) deleted.
** DO NOT DELETE THE USER'S HOME DIRECTORY.
* Merge patchset with username change (UID remains the same).
* Run puppet on affected hosts, and they will create the new user (using the same UID.)
* Batch move the contents of the old user home into the new user home.

## ldap-only

Before adding someone to LDAP, check whether there's an existing entry in puppet.git:modules/admin/data/data.yaml.

If the user already has shell access, no further change is needed. You can proceed with the LDAP change. If not, add the user to the ldap_only_users table at the end of the file.Existing users are checked automatically they exist on ldap, if a user is removed from ldap, add it to the ldap-absent group. A user can be on the 'absent' group (former cluster access, now removed from /etc/passwd) and on the ldap-only group (only has ldap access now).\

## Same posix group, different members on different nodes
Rarely used feature (USE WITH CARE AND CAUTION):

You can specify a name other than the group name in yaml to be the actual
on server posix name.  This means you can have the same group name across
different boxes with a unique description and grouping in yaml.  This can be
useful for sharing sensitive data across servers, or for backups, etc.

Such as:
```yaml
groups:
  backup-files-foo:
    gid: 1000
    posix_name: stats
    members: [people who need backups on foo]

  backup-files-bar:
    gid: 1000
    posix_name: stats
    members: [people who need backups on bar]
```

Assignment:
```puppet
  node /foo/ {
    class { 'admin': groups => ['backup-files-foo'] }
  }

  node /bar/ {
    class { 'admin': groups => ['backup-files-bar'] }
  }
```

If you try to apply two groupings with the same posix names on a single node you see:

    Duplicate definition: Admin::Group[$POSIX_NAME] is already defined


## System users and groups

Sometimes it is useful to declare that a system user should be in a group with other
human user accounts.  This module can manage system users, however it is also possible
for system users to be managed directly in one of the other puppet modules.

We want system user and group uid and gids to be synchronized across the fleet.
To do this, puppet needs to manage all system users somewhere, whether that is in
the relevant puppet classes or in this admin module is up to your judgement.

A good convention may be to manage service/daemon system users (ones that run
actual daemons) in the relevant puppet classes, but use this admin module to
manage 'system' users and groups for use by human users.  E.g. in the analytics cluster,
teams need a shared user with which they can productionize jobs that are not
connected with a human user account.  In this case, we declare the
system users and groups in this admin module.

If your daemon system user declares a uid/gid in a puppet class, please add a
commented out placeholder entry in `data.yaml` anyway.  This will help
avoid a conflict if someone tries to add a new system user in `data.yaml` but
is not aware of your use of the uid/gid somewhere else in pppet.

Add system users to a group by providing a list of system_members in your group declaration.
```yaml
groups:
  team-group:
    gid: 701
    members: [human_a, human_b]
    privileges: ['ALL = (team-system-user) NOPASSWD: ALL']
    system_members: [team-system-user]
```
This example will add the `team-system-user` (likely declared elsewere in admin.yaml) to the
`team-group`, and will allow all human members of `team-group` to `sudo -u team-system-user`.

Your system user *must* already exist by the time the admin module ensures group membership.
If it doesn't, the groupmembers exec will fail.
