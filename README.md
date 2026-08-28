# dotfiles

Personal configuration for macOS, shared command-line tools, and retained Linux desktop environments. The repository stays mostly flat by tool so configs remain easy to find; Linux-only desktop files live under `linux/`.

## One-Line Mac Setup

Paste this into a vibecoding agent on a new Mac:

> Clone `https://github.com/roerohan/.dotfiles.git` into `~/Documents/Repos/dotfiles`, read `AGENTS.md` and `MACOS_SETUP.md`, ask me which default-selected applications I want, then set up the Mac end to end using latest stable Homebrew packages, back up conflicting files, use `ln -s` to link repository-managed configs into `~/.config` or their required home paths instead of copying them, and verify every installation and link.

The full agent-first procedure is [`MACOS_SETUP.md`](MACOS_SETUP.md). Repository-specific instructions and durable preferences live in [`AGENTS.md`](AGENTS.md).

## Layout

```text
dotfiles/
├── aerospace/       # macOS window manager
├── ghostty/         # terminal configuration
├── jj/              # Jujutsu configuration
├── lazygit/         # Lazygit configuration
├── nvim/            # AstroNvim configuration and fallback setup
├── opencode/        # OpenCode configuration, agents, skills, and plugins
├── tmux/            # tmux configuration
├── tmuxinator/      # tmuxinator notes
├── zsh/             # shell configuration
├── linux/           # Linux-only desktop and system configuration
├── sbx/             # sandbox kits
├── MACOS_SETUP.md   # primary new-Mac runbook
└── remote-box.sh    # Ubuntu remote-box fallback bootstrap
```

Other tool directories remain at root when they are shared, active, or easier to discover there. Historical configurations are retained until deliberately archived; old does not automatically mean disposable.

## Linking Policy

Tracked config files are the source of truth. New setups should create absolute symbolic links from the expected home location back into this clone:

```sh
ln -s "$HOME/Documents/Repos/dotfiles/ghostty/config" "$HOME/.config/ghostty/config"
```

Never replace a conflicting file blindly. Inspect it, back it up, then create the symlink. Do not copy tracked configs into `$HOME`; copied files drift between devices with remarkable efficiency.

## Linux

Linux-only desktop configs are grouped under [`linux/`](linux/). The Ubuntu remote-agent bootstrap remains [`remote-box.sh`](remote-box.sh):

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/roerohan/.dotfiles/main/remote-box.sh)"
```

The Manjaro package snapshot is retained at [`linux/package_list.txt`](linux/package_list.txt) for reference rather than treated as a current universal install manifest.

## Contributing

Use prefixed commit messages such as `feat:`, `fix:`, `refactor:`, `docs:`, and `lint:`. See [`CONTRIBUTING.md`](CONTRIBUTING.md).

## License

See [`LICENSE`](LICENSE).
