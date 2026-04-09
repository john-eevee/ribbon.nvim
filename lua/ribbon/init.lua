-- Ribbon.nvim - Bookmark management plugin
-- Exposes API for bookmark management without default keybindings

local api = {}

-- Require modules (will be implemented next)
local core = require('ribbon.core')
local signs = require('ribbon.signs')
local persistence = require('ribbon.persistence')
local tree = require('ribbon.tree')

-- Initialize the plugin
function api.setup(options)
    -- Merge user options with defaults
    api.options = vim.tbl_deep_extend('force', {
        -- Default options can go here
        sign_priority = 10,
        sign_text = '■', -- Default sign for anonymous bookmarks
        enable_signs = true,
        data_dir = vim.fn.stdpath('data') .. '/ribbon',
    }, options or {})

    -- Initialize subsystems
    core.init(api.options)
    signs.init(api.options)
    persistence.init(api.options)
    tree.init(api.options)
end

-- Public API functions
function api.toggle()
    core.toggle_bookmark()
end

function api.mark(char)
    core.set_mnemonic_bookmark(char)
end

function api.jump(char)
    core.jump_to_bookmark(char)
end

function api.annotate()
    core.annotate_bookmark()
end

function api.toggle_tree()
    tree.toggle()
end

function api.clear_all()
    core.clear_all_bookmarks()
end

return api