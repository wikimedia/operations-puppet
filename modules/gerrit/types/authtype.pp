# There are other auth types but we limit it to 2 for now.
# You can find more at https://gerrit-review.googlesource.com/Documentation/config-gerrit.html#auth
type Gerrit::AuthType = Enum['DEVELOPMENT_BECOME_ANY_ACCOUNT', 'LDAP']
