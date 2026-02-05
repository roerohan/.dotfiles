# Aerospace

i3-like window manager for MacOS.

## Installation

```sh
brew install --cask nikitabobko/tap/aerospace
```

## Config

```sh
mkdir -p ~/.config/aerospace/
ln -s "`pwd`/aerospace.toml" ~/.config/aerospace/aerospace.toml
```

### Aerospace Configuration

- **Config File Location**: The main configuration file is `~/.config/aerospace/aerospace.toml`.
- **Custom Keybindings**: Edit the `aerospace.toml` to customize keybindings and behaviors.
- **Logs**: Configuration errors will be logged in `~/.config/aerospace/logs`.
- **Advanced Options**: Advanced users can specify additional options like workspace layouts and snapping rules in the configuration file.