# capytools
---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/kaelyx-dev/capytools/main/install.sh | bash
```

After install, open a new shell or run:

```bash
source ~/.bashrc
```

---

## Commands

| Command                    | Description                                              |
|----------------------------|----------------------------------------------------------|
| `capytools update`         | Fetch and install the latest release                     |
| `capytools rollback`       | Switch `CURRENT_VERSION` back to `PREVIOUS_VERSION`      |
| `capytools version`        | Show installed and currently-loaded versions             |
| `capytools list`           | List all versions installed on disk                      |
| `capytools lock <version>` | Pin updates to a specific version                        |
| `capytools unlock`         | Remove version pin and resume tracking latest            |

---

## How It Works

- `install.sh` downloads the latest GitHub release, extracts `aliases.sh` and
  `functions.sh` into `~/.capytools/versions/<version>/`, and writes
  `~/.capytools/capytools.conf.env`.
- `entry.sh` is sourced from `~/.bashrc` on every new shell. It reads
  `capytools.conf.env`, then sources the current version's `functions.sh`
  followed by `aliases.sh`.
- Old version directories are never deleted, enabling `capytools rollback`.

---

## Release Workflow

1. Edit `aliases.sh` and/or `functions.sh` on `main`.
2. Bump `CAPYTOOLS_VERSION` in `functions.sh` to match the tag you are about
   to create.
3. Commit and push to `main`.
4. Tag the release:
   ```bash
   git tag v1.2.0 && git push origin v1.2.0
   ```
5. On GitHub: **Releases** → **Draft new release** → pick the tag → **Publish**.

> Note: `install.sh` queries `/releases/latest`, which only returns published
> Release objects. A bare tag without a published release will not be picked up.

---

## Local Dev Testing (before cutting a tag)

```bash
mkdir -p ~/.capytools/versions/dev
ln -sf "$PWD/aliases.sh"   ~/.capytools/versions/dev/aliases.sh
ln -sf "$PWD/functions.sh" ~/.capytools/versions/dev/functions.sh
echo "CURRENT_VERSION=dev" > ~/.capytools/capytools.conf.env
```

Then open a new shell to load changes live.

---

## Install Directory Layout

```
~/.capytools/
├── capytools.conf.env        # CURRENT_VERSION + PREVIOUS_VERSION (managed by install.sh)
├── user-capytools.conf.env   # user overrides — edit freely, never touched by updates
├── entry.sh                  # stable shim (written once, never overwritten)
├── install.sh                # cached copy for `capytools update`
└── versions/
    ├── 1.0.0/
    │   ├── aliases.sh
    │   ├── functions.sh
    │   └── capytools.conf.env
    ├── 1.1.0/
    │   ├── aliases.sh
    │   ├── functions.sh
    │   └── capytools.conf.env
    └── ...
```

---

## Configuration

System defaults live in `versions/<ver>/capytools.conf.env` and are distributed
with each release. User overrides live in `~/.capytools/user-capytools.conf.env`,
which is created blank on first install and **never modified by updates**.

All config variables use the `CAPY_` prefix to avoid polluting the shell environment.

| Variable            | Default                | Description                                                                  |
|---------------------|------------------------|------------------------------------------------------------------------------|
| `CAPY_GREETING`     | `hello from capytools` | Message printed by the `capyhi` alias                                        |
| `CAPY_COLOR_PROMPT` | `true`                 | Reserved for prompt colour customisation                                     |
| `CAPY_LOCK_VERSION` | _(unset)_              | Pin `capytools update` to a specific version instead of fetching the latest  |

To override a value, add it to `~/.capytools/user-capytools.conf.env`:

```bash
# ~/.capytools/user-capytools.conf.env
CAPY_GREETING="hey there"
CAPY_LOCK_VERSION="1.2.0"
```

Or use the built-in commands:

```bash
capytools lock 1.2.0   # pins to 1.2.0
capytools unlock       # removes pin, resumes tracking latest
```

> `CAPYTOOLS_HOME` is a shell-level override (not a `CAPY_` var) — set it in
> your shell environment before `entry.sh` is sourced if you want capytools
> installed somewhere other than `~/.capytools`.
