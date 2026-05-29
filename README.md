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

The script installs apt dependencies, GitHub CLI (`gh`), Oh My Zsh, nvm/Node LTS, Bun, OpenCode, tmux config, AstroNvim config, the sbx `opencode-config` kit, and this repo under `~/dotfiles`.

It prompts for `OPENAI_API_KEY` and `ANTHROPIC_API_KEY`, writes them to `~/.zshenv`, copies `zsh/zshrc` to `~/.zshrc`, and patches the copied file for Ubuntu instead of symlinking it. That copy is intentional: the source zshrc still has macOS baggage, because of course it does.

It also asks whether to use existing SSH keys or generate new ones for GitHub auth and Git commit signing. If keys are generated, the script prints the public-key paths plus `gh ssh-key add ...` commands and GitHub settings URLs at the end. It can optionally authenticate `gh` and upload the keys for you.

Git config is copied from this repo when needed, then normalized for the remote box: `user.name`, `user.email`, GitHub SSH URL rewriting, default branch, auto upstream setup, and SSH commit signing when a signing key is available.

Existing files are not overwritten blindly. If a config already matches, it is skipped. If it differs, the script asks before replacing and backs up the old file first. Shocking restraint from a setup script, frankly.

Most configuration steps are optional. You can skip GitHub CLI install/auth, SSH key setup, Git globals, tmux links, OpenCode config, sbx kit setup, zshrc copy, and Neovim setup, then handle them manually later if you prefer artisanal suffering.

OpenCode is configured broadly for remote-box work: normal read/edit/bash/tool usage is allowed, while `.env` files, `~/.zshenv`, `~/.npmrc`, `~/.netrc`, secret directories, private keys, SSH/AWS/GCP/GPG/Kube material, and OpenCode auth files stay denied. Obvious shell-based secret reads like `env`, `printenv`, and `cat ~/.zshenv` are denied too; this is a convenience guard, not a military-grade sandbox. Shocking, I know.

At the end, the script validates locally with `zsh -n`, `opencode debug config`, git identity checks, tmux config loading, and a headless Neovim startup. It also runs `opencode run` to inspect the completed setup and return a PASS/FAIL report.

Useful overrides:

```sh
DOTFILES_DIR=~/src/dotfiles \
DOTFILES_REPO=https://github.com/roerohan/.dotfiles.git \
OPENCODE_VALIDATE_MODEL=anthropic/claude-sonnet-4-6 \
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
