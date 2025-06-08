# nvide

nvide: Personal vim configurations, which using Neovim as an IDE, powered by modern nvim plugins such as coc.nvim, Leaderf and more.

## How to install

### neovim Appimage
1. Download latest (prerelease) neovim and rename the package as `nvim`.
2. Download `nvim.config.tar.gz` from github action of this repository.
3. unzip the file and put it together with nvim like: `nvim nvim.config/`, so that when you run `./nvim`, it will use configurations in the `nvim.config`.

### console install
1. `sudo apt-get install neovim` for ubuntu and `brew install neovim` for macOS.
2. Download `nvim.config.tar.gz` from github action of this repository.
3. unzip the file, and `cp -r nvim.config/* ~/.config`.

So, let's start enjoy coding...
