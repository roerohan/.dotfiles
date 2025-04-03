# Ghostty

Cross platform terminal emulator with sane defaults.

## Installation

```sh
brew install --cask ghostty
```

## Config

```sh
mkdir -p ~/.config/ghostty/
ln -s "`pwd`/config" ~/.config/ghostty/config
```

## Supplementary tools

```sh
# tmux
brew install tmux

# zsh syntax highlighting
brew install zsh-syntax-highlighting
echo "source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ${ZDOTDIR:-$HOME}/.zshrc

brew install zsh-autosuggestions
echo "source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ${ZDOTDIR:-$HOME}/.zshrc
```
