# DevOps setup

Optional toolchain plus per-directory git and AWS identity switching. Back to the [README](../README.md).

## DevOps toolchain (optional)

```sh
./development-tools.sh
```

A separate, also-idempotent script (run `setup.sh` first) for a DevOps-flavored
toolchain that not everyone using this repo needs:

| Tool | What it does |
|---|---|
| [VS Code](https://code.visualstudio.com) | Editor, for the times a full IDE beats Neovim |
| [gvm](https://gvm.sh) | Go version manager — installed via its own installer (no Homebrew formula exists), `gvm install latest` to get Go itself |
| [OpenTofu](https://opentofu.org) / [Terragrunt](https://terragrunt.gruntwork.io) | Infrastructure as code — used deliberately instead of HashiCorp's `terraform` CLI (BSL license); Neovim's Terraform formatter is wired to `tofu fmt` for the same reason |
| [Ansible](https://www.ansible.com) | Config management (`ansible-vault` ships as a subcommand) |
| [kubectl](https://kubernetes.io/docs/reference/kubectl/) / [kubectx](https://github.com/ahmetb/kubectx) | Kubernetes CLI + fast context/namespace switching (`kubectx`/`kubens`) |
| [k9s](https://k9scli.io) | Terminal Kubernetes UI — themed Catppuccin Mocha (transparent), matching WezTerm/Neovim (`k9s/`) |
| [sofka](https://sofka.rs) | Kubernetes TUI (Rust, k9s-inspired) — Flux/Argo CD built in, native incident view, themed Catppuccin Mocha, matching WezTerm/Neovim/k9s (`sofka/`); `Ctrl-T` opens a pane (a Tern block split inside Tern, else a WezTerm pane) with `kubectl`/`helm` pinned to Sofka’s active context and namespace, including from tmux sessions with stale WezTerm socket state |
| [Helm](https://helm.sh) + [helm-diff](https://github.com/databus23/helm-diff) | Kubernetes package manager + `helm diff upgrade`/`helm diff rollback` plugin (previews changes before applying) |
| [Freelens](https://freelens.app) | Kubernetes IDE — open-source Lens fork |
| [lazygit](https://github.com/jesseduffield/lazygit) | Terminal git UI |
| [jq](https://jqlang.org) / [yq](https://github.com/mikefarah/yq) | JSON / YAML processors |
| [Google Cloud CLI](https://cloud.google.com/cli) / [AWS CLI v2](https://aws.amazon.com/cli) | `gcloud`/`gsutil`/`bq` and `aws` — `gke-gcloud-auth-plugin` is installed alongside gcloud (`kubectl` needs it to auth against GKE clusters); AWS has two SSO profiles (`cekataiofficial`/`personal`) that auto-switch by directory, same pattern as git identity — see below |
| [Python](https://www.python.org) / [Node](https://nodejs.org) / [pnpm](https://pnpm.io) | Runtimes — `npm` ships with Node |
| [HTTPie](https://httpie.io) | `http`/`https` CLI (friendlier curl) plus the [HTTPie for Desktop](https://httpie.io/product) GUI companion |
| [Apidog](https://apidog.com) | API development platform — design, mock, test, and document APIs in one GUI app |

`kubectl`, `yq`, `tofu`, and `aws` completions are wired into
`zsh/completions.zsh` automatically once those binaries are on PATH — no
extra setup.

**Neovim's language coverage needs this script too.** `setup.sh` alone gets
you LSP/format/lint for Lua, Bash, and C/C++. Go, Node/TS/JS, Python, and
Terraform additionally need `go` (via `gvm install latest`, above), `node`,
and `python` on PATH before Neovim can install their language servers —
without them, Mason logs a failed install for just those servers (`:Mason`
or `:MasonLog` to check) and everything else keeps working.

## git identity switching

`git/.gitconfig` uses `includeIf "gitdir:...` to load a different identity
and SSH key depending on which directory a repo lives under, no manual
`git config` per-repo needed:

| Directory | Identity file | Used for |
|---|---|---|
| `~/Artifacts/labs/` | `.gitconfig-personal` | Personal repos, pushes as `davidsugianto` |
| `~/Artifacts/work/` | `.gitconfig-work` | Work repos, rewrites `github.com/cekataiofficial/*` to SSH |

Both currently share the same email/SSH key (`~/.ssh/personal.david.sugianto.pem`)
— split `.gitconfig-work` once a separate work identity/key exists; it's a
plain `[user]`/`[core]` block, nothing else depends on it matching personal.

**Security note carried over from the original config**: `core.sshCommand`
in both identity files sets `StrictHostKeyChecking=no`, which skips SSH host
key verification (accepts any host key without prompting or checking
`known_hosts`). That's weaker than the default and was already the case
before this repo — tighten it if you'd rather have the prompt back.

## AWS profile switching

`zsh/functions.zsh` sets `AWS_PROFILE` automatically based on directory, via
a `chpwd` hook — same directory split as git identity above:

| Directory | AWS profile | Used for |
|---|---|---|
| `~/Artifacts/work/cekataiofficial/` | `cekataiofficial` | Work AWS account |
| `~/Artifacts/labs/` | `personal` | Personal AWS account |

Outside both trees `AWS_PROFILE` is unset rather than left stale, so `aws`
commands fail closed instead of silently hitting the wrong account. Both
profiles authenticate via AWS SSO (IAM Identity Center) — set up once per
machine with `aws configure sso --profile cekataiofficial` and
`aws configure sso --profile personal` (interactive; not part of `setup.sh`
since it needs a browser login), then re-auth per session with
`aws sso login --profile <name>` when the cached SSO token expires.
