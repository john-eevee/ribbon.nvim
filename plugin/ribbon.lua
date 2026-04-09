-- Ribbon.nvim plugin auto-load file
-- This file is automatically executed on Neovim startup

local ribbon = require('ribbon')

vim.api.nvim_create_user_command('Ribbon', function(opts)
    local args = opts.fargs
    if #args == 0 then
        vim.cmd('Ribbon toggle')
        return
    end
    
    local cmd = args[1]
    if cmd == 'toggle' then
        ribbon.toggle()
    elseif cmd == 'toggle_tree' then
        ribbon.toggle_tree()
    elseif cmd == 'clear' then
        ribbon.clear_all()
    else
        vim.notify('Ribbon: Unknown command: ' .. cmd, vim.log.levels.WARN)
    end
end, {
    nargs = '*',
    desc = 'Ribbon bookmark manager',
})

return ribbon
