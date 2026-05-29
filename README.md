[![Issues][issues-shield]][issues-url]

<!-- PROJECT LOGO -->
<br />
<p align="center">
  <!-- <a href="https://github.com/roerohan/.dotfiles">
    <img src="https://project-logo.png" alt="Logo" width="80">
  </a> -->

  <h3 align="center">.dotfiles</h3>

  <p align="center">
    Configuration files for my Linux system.
    <br />
    <a href="https://github.com/roerohan/.dotfiles"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/roerohan/.dotfiles">View Demo</a>
    ·
    <a href="https://github.com/roerohan/.dotfiles/issues">Report Bug</a>
    ·
    <a href="https://github.com/roerohan/.dotfiles/issues">Request Feature</a>
  </p>
</p>



<!-- TABLE OF CONTENTS -->
## Table of Contents

* [About the Project](#about-the-project)
* [Getting Started](#getting-started)
  * [Prerequisites](#prerequisites)
  * [Installation](#installation)
* [Usage](#usage)
* [Roadmap](#roadmap)
* [Contributing](#contributing)
* [License](#license)
* [Contributors](#contributors-)



<!-- ABOUT THE PROJECT -->
## About The Project

This repository consists of configuration files for my Linux system.

<!-- GETTING STARTED -->
## Getting Started

To get a local copy up and running follow these simple steps.

### Remote Ubuntu Bootstrap

Paste this into a fresh Ubuntu remote box to install the shell/editor/agent setup and clone this repo:

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/roerohan/.dotfiles/main/remote-box.sh)"
```

The script installs apt dependencies, the latest stable Neovim (from the official GitHub release tarball, not the ancient apt one), GitHub CLI (`gh`), Oh My Zsh, nvm/Node LTS, Bun, OpenCode, tmux config, AstroNvim config, the sbx `opencode-config` kit, and this repo under `~/dotfiles`. Pin a specific Neovim with `NEOVIM_VERSION=v0.11.0`.

It copies `zsh/zshrc` to `~/.zshrc` and patches the copied file for Ubuntu instead of symlinking it. That copy is intentional: the source zshrc still has macOS baggage, because of course it does.

`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, and `GITHUB_TOKEN` are never stored on the box. The script reads them from the session environment (forwarded via SSH `SendEnv`/`AcceptEnv`): OpenCode picks up the API keys from `env` at runtime, and `gh` reads `GITHUB_TOKEN` directly (the script also sets `gh config set git_protocol ssh` so git stays on the forwarded agent). The script can optionally configure remote `sshd` with `AcceptEnv OPENAI_API_KEY ANTHROPIC_API_KEY GITHUB_TOKEN`; pair that with local SSH config `SendEnv OPENAI_API_KEY ANTHROPIC_API_KEY GITHUB_TOKEN` and connect from a shell where those vars are exported. No secrets on disk, no `~/.zshenv` exports, no `gh auth login` on the box, no prompting. Session-scoped secrets, the way the gods intended.

It does not create SSH keys on the remote box. Use SSH agent forwarding instead, for example `ssh -A rohan@your-remote-ip`. At the end, the script prints the local and remote commands needed to verify forwarded GitHub SSH auth. Fewer private keys scattered across EC2 like confetti. Radical.

Git config is copied from this repo when needed, then normalized for the remote box: `user.name`, `user.email`, GitHub SSH URL rewriting, default branch, and auto upstream setup. Commit signing is disabled by default on the remote to avoid broken signing config unless you choose to set it up manually.

Existing files are not overwritten blindly. If a config already matches, it is skipped. If it differs, the script asks before replacing and backs up the old file first. Shocking restraint from a setup script, frankly.

Most configuration steps are optional. GitHub CLI install/auth and Git globals default to skip unless you opt in. You can also skip tmux links, OpenCode config, sbx kit setup, zshrc copy, and Neovim setup, then handle them manually later if you prefer artisanal suffering.

OpenCode is configured broadly for remote-box work: normal read/edit/bash/tool usage is allowed, while `.env` files, `~/.zshenv`, `~/.npmrc`, `~/.netrc`, secret directories, private keys, SSH/AWS/GCP/GPG/Kube material, and OpenCode auth files stay denied. Obvious shell-based secret reads like `env`, `printenv`, and `cat ~/.zshenv` are denied too; this is a convenience guard, not a military-grade sandbox. Shocking, I know.

At the end, the script validates locally with `zsh -n`, `opencode debug config`, git identity checks, tmux config loading, and a headless Neovim startup. It also runs `opencode run` to inspect the completed setup and return a PASS/FAIL report.

Useful overrides:

```sh
DOTFILES_DIR=~/src/dotfiles \
DOTFILES_REPO=https://github.com/roerohan/.dotfiles.git \
OPENCODE_VALIDATE_MODEL=anthropic/claude-sonnet-4-6 \
NEOVIM_VERSION=v0.11.0 \
bash -c "$(curl -fsSL https://raw.githubusercontent.com/roerohan/.dotfiles/main/remote-box.sh)"
```

Skip the final OpenCode validation when API keys are not ready:

```sh
RUN_OPENCODE_VALIDATE=0 bash -c "$(curl -fsSL https://raw.githubusercontent.com/roerohan/.dotfiles/main/remote-box.sh)"
```

Force the final OpenCode validation even when no `OPENAI_API_KEY` or `ANTHROPIC_API_KEY` is loaded:

```sh
OPENCODE_FORCE_VALIDATE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/roerohan/.dotfiles/main/remote-box.sh)"
```

### Prerequisites

This is an example of how to list things you need to use the software and how to install them.
* npm
```sh
npm install npm@latest -g
```

### Installation
  
1. Clone the Repo
```sh
git clone https://github.com/roerohan/.dotfiles.git
```
2. Install NPM packages
```sh
npm install
```

### jj Setup

1. Install `jj` by following the official instructions:
   ```sh
   brew install jj
   ```

2. Configure `jj` with your preferences or default configuration.
   
   For more details on configuration, refer to the [jj documentation](https://github.com/martinvonz/jj).




<!-- USAGE EXAMPLES -->
## Usage

Use this space to show useful examples of how a project can be used. Additional screenshots, code examples and demos work well in this space. You may also link to more resources.

_For more examples, please refer to the [Documentation](https://example.com)_



<!-- ROADMAP -->
## Roadmap

See the [open issues](https://github.com/roerohan/.dotfiles/issues) for a list of proposed features (and known issues).



<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to be learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'feat: Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

You are requested to follow the contribution guidelines specified in [CONTRIBUTING.md](./CONTRIBUTING.md) while contributing to the project :smile:.

<!-- LICENSE -->
## License

Distributed under the MIT License. See [`LICENSE`](./LICENSE) for more information.


<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[roerohan-url]: https://roerohan.github.io
[issues-shield]: https://img.shields.io/github/issues/roerohan/.dotfiles.svg?style=flat-square
[issues-url]: https://github.com/roerohan/.dotfiles/issues
