# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

**Setup:**
```bash
bundle install
bundle exec rake spec_prep   # Install fixture modules (required before running specs)
```

**Tests:**
```bash
bundle exec rake spec                    # Run all unit tests
bundle exec rspec spec/unit/puppet/provider/logical_volume/lvm_spec.rb  # Run a single spec file
bundle exec rspec spec/unit/puppet/provider/logical_volume/lvm_spec.rb:42  # Run a specific example
```

**Linting and validation:**
```bash
bundle exec rake lint        # puppet-lint (configured via .puppet-lint.rc)
bundle exec rake rubocop     # RuboCop Ruby style checks
bundle exec rake validate    # Syntax check Ruby, Puppet manifests, and metadata
bundle exec rake syntax      # Puppet manifest and Hiera syntax check
```

**All checks (pre-release):**
```bash
bundle exec rake release_checks
```

## Architecture

This is a Puppet module that manages Linux LVM and AIX logical volume resources. It follows standard Puppet module structure.

### Resource type dependency chain

```
filesystem -> logical_volume -> volume_group -> physical_volume(s)
```

Each layer must be defined before the one above it. The `lvm::volume` defined type in `manifests/volume.pp` wraps this full chain for the common single-PV case.

### Types and providers (`lib/puppet/`)

Each of the four resource types (`logical_volume`, `volume_group`, `physical_volume`, `filesystem`) has:
- A **type** definition in `lib/puppet/type/` — declares parameters, properties, validation, and `autorequire` relationships
- A **Linux provider** (`lvm`) in `lib/puppet/provider/<type>/lvm.rb` — wraps LVM CLI commands (`lvcreate`, `lvextend`, `vgcreate`, etc.)
- An **AIX provider** (`aix`) in `lib/puppet/provider/<type>/aix.rb` — wraps AIX-specific commands; uses `defaultfor`/`confine` on `os.name: :AIX`

The Linux providers use `commands` to declare required binaries (e.g., `lvcreate`, `lvremove`) and `optional_commands` for optional ones (e.g., `xfs_growfs`, `resize4fs`). Puppet raises an error at catalog application time if a required command is missing.

### Boolean parameter pattern

Many boolean parameters accept `[:true, true, 'true', :false, false, 'false']` to handle Puppet's symbol-vs-string boolean ambiguity. When passing these values to shell commands, convert explicitly — e.g., `[:true, true, 'true'].include?(value) ? 'y' : 'n'`.

### Facter facts (`lib/facter/`)

Four custom facts: `lvm_support`, `logical_volumes`, `physical_volumes`, `volume_groups`. These are used internally and in manifests; some flat `lvm_vg_*` / `lvm_pv_*` facts are deprecated in favour of structured facts.

### Puppet functions (`functions/`)

- `lvm::bytes_to_size` — converts bytes integer to human-readable size string
- `lvm::size_to_bytes` — converts size string (e.g. `"20G"`) to bytes

### Helper (`lib/puppet_x/lvm/output.rb`)

`Puppet_X::LVM::Output.parse` parses columnar LVM CLI output (e.g. `lvs`, `vgs`) into a hash, stripping column name prefixes (e.g., `lv_name` → `name`).

### Manifests (`manifests/`)

- `lvm` class — optional `lvm2` package management + iterates `$volume_groups` hash via `create_resources`
- `lvm::volume` defined type — convenience wrapper for the full PV→VG→LV→FS chain
- `lvm::volume_group` / `lvm::logical_volume` / `lvm::physical_volume` — defined types iterated from the `lvm` class hash

### Tasks (`tasks/`)

Bolt tasks for imperative operations: `ensure_pv`, `ensure_vg`, `ensure_lv`, `ensure_fs`, `extend_lv`, `extend_vg`, `mount_lv`. Each task has a `.rb` implementation and a `.json` parameter schema.

### Plans (`plans/`)

`lvm::expand` — Bolt plan for expanding an LV and its filesystem.

### Test structure (`spec/`)

- `spec/unit/puppet/provider/<type>/` — provider unit tests using Mocha stubs (`stub_everything`, `stubs`, `expects`)
- `spec/unit/puppet/type/` — type unit tests
- `spec/unit/facter/` — fact unit tests
- `spec/acceptance/` — Litmus acceptance tests (require provisioned targets)
- `spec/lib/helpers.rb`, `spec/lib/matchers.rb` — shared test helpers
