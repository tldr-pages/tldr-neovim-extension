# tldr-neovim-extension

TLDR Neovim Extension is a plugin that integrates TLDR pages directly into Neovim. TLDR is a community-driven collection of simplified and community-contributed man pages. This plugin allows you to access TLDR pages directly from within Neovim, making it easier to find concise explanations and examples for various commands.

## Installation
### Using Packer
Add the following line to your Neovim configuration file

```lua
use { 'tldr-pages/tldr-neovim-extension' }
```
Save the configuration file and restart Neovim.

Run the following command in Neovim to install the plugin:
```
:PackerInstall
```
Once the installation is complete, add the following line to your configuration to enable the plugin:

```lua
require('tldr').setup()
```
This line should be placed after the use statement for the plugin in your configuration file.

Save the configuration file, and the TLDR Neovim Extension will be active the next time you start Neovim.

## Usage

Once the plugin is installed and set up, you can access TLDR pages from within Neovim. Use the following commands to interact with the plugin:
```
:Tldr <topic>: Open a TLDR page for a specific topic.
:TldrList: List all available TLDR pages. (TODO)
:TldrUpdate: Update the local TLDR repository to get the latest pages. (TODO, currently auto updates pages in the background)
```

## Contributions

We welcome contributions to the TLDR Neovim Extension! If you'd like to help improve the plugin or have ideas for new features, please don't hesitate to get involved. Here's how you can contribute:

- Fork this repository.
- Make your changes or add new features.
- Submit a pull request with a clear description of your changes.
