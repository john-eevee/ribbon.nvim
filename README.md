# Ribbon.nvim

A Neovim plugin for managing bookmarks, inspired by IntelliJ's bookmark system. Bookmarks are persistent by project and can be grouped and accessed by mnemonic characters (A-Z, 0-9).

## Features

- **Persistent Bookmarks**: Bookmarks are saved per-project (based on working directory)
- **Mnemonic Bookmarks**: Assign letters (A-Z) or numbers (0-9) for quick navigation
- **Anonymous Bookmarks**: Toggle bookmarks without mnemonics
- **Groups**: Organize bookmarks into named groups (default: "Main")
- **Annotations**: Add descriptions to your bookmarks
- **Telescope Integration**: Search and navigate bookmarks via Telescope
- **Side Tree View**: Visual overview of all bookmarks using nui.nvim

## Requirements

- Neovim 0.9+
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) (for path handling)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (optional, for Telescope integration)
- [nui.nvim](https://github.com/MunifTanjim/nui.nvim) (optional, for side tree view)

## Installation

Using lazy.nvim:

```lua
{
    'your-name/ribbon.nvim',
    dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-telescope/telescope.nvim',
        'MunifTanjim/nui.nvim',
    },
}
```

## Configuration

```lua
require('ribbon').setup({
    sign_priority = 10,
    sign_text = '■',  -- Default sign for anonymous bookmarks
    enable_signs = true,
    data_dir = vim.fn.stdpath('data') .. '/ribbon',
})
```

## Usage

Ribbon does not set any default keybindings. Configure your own mappings:

```lua
vim.keymap.set('n', 'mm', require('ribbon').toggle)           -- Toggle anonymous bookmark
vim.keymap.set('n', 'm0', function() require('ribbon').mark('0') end)  -- Set mnemonic bookmark
vim.keymap.set('n', 'm1', function() require('ribbon').mark('1') end)
vim.keymap.set('n', 'mA', function() require('ribbon').mark('A') end)
vim.keymap.set('n', "'0", function() require('ribbon').jump('0') end)  -- Jump to mnemonic
vim.keymap.set('n', "'A", function() require('ribbon').jump('A') end)
vim.keymap.set('n', 'me', require('ribbon').annotate)        -- Annotate current bookmark
vim.keymap.set('n', 'mt', require('ribbon').toggle_tree)      -- Toggle side tree view
vim.keymap.set('n', 'mc', require('ribbon').clear_all)        -- Clear all bookmarks
```

### Auto-configure All Mnemonics (A-Z, 0-9)

To automatically set up all 36 mnemonic keybindings, use this helper in your config:

```lua
-- Ribbon mnemonics setup
-- Maps: m{char} to set bookmark, '{char} to jump
local function setup_ribbon_mnemonics()
    local chars = {}
    -- 0-9
    for i = 0, 9 do table.insert(chars, tostring(i)) end
    -- A-Z
    for i = 65, 90 do table.insert(chars, string.char(i)) end
    
    for _, char in ipairs(chars) do
        vim.keymap.set('n', 'm' .. char, function()
            require('ribbon').mark(char)
        end)
        vim.keymap.set('n', "'" .. char, function()
            require('ribbon').jump(char)
        end)
    end
end

setup_ribbon_mnemonics()

-- Optional: other ribbon bindings
vim.keymap.set('n', 'mm', require('ribbon').toggle)
vim.keymap.set('n', 'me', require('ribbon').annotate)
vim.keymap.set('n', 'mt', require('ribbon').toggle_tree)
vim.keymap.set('n', 'mc', require('ribbon').clear_all)
```

This creates the following mappings:

| Set Bookmark | Jump |
|--------------|------|
| `m0` - `m9` | `'0` - `'9` |
| `mA` - `mZ` | `'A` - `'Z` |
| `mm` (anonymous) | - |

## API

| Function | Description |
|----------|-------------|
| `require('ribbon').toggle()` | Toggle anonymous bookmark on current line |
| `require('ribbon').mark(char)` | Set/toggle mnemonic bookmark (A-Z, 0-9) |
| `require('ribbon').jump(char)` | Jump to mnemonic bookmark |
| `require('ribbon').annotate()` | Add/edit annotation for bookmark at cursor |
| `require('ribbon').toggle_tree()` | Open/close the side tree view |
| `require('ribbon').clear_all()` | Remove all bookmarks for current project |

## Telescope Integration

After installing, load the Telescope extension:

```lua
-- In your Telescope config
telescope.load_extension('ribbon')
```

Then use:

```vim
:Telescope ribbon
```

### Telescope Keybindings

| Key | Action |
|-----|--------|
| `<CR>` | Jump to selected bookmark |
| `d` | Delete selected bookmark |
| `a` | Annotate selected bookmark |

## Side Tree View

The side tree view shows all bookmarks organized by group:

| Key | Action |
|-----|--------|
| `<CR>` | Jump to selected bookmark |
| `d` | Delete selected bookmark |
| `e` | Annotate selected bookmark |
| `q` | Close tree view |
| `<Esc>` | Close tree view |

## Commands

You can also use the `:Ribbon` command:

```vim
:Ribbon toggle        -- Toggle anonymous bookmark
:Ribbon toggle_tree  -- Toggle side tree
:Ribbon clear         -- Clear all bookmarks
```

## Data Storage

Bookmarks are stored in `~/.local/share/nvim/ribbon/` as JSON files, one per project (identified by working directory).

## License

MIT
