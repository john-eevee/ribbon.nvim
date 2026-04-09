-- Tree view for ribbon bookmarks using nui.nvim

local M = {}

-- Options from setup
M.options = {}

-- NUI components
local popup = require('nui.popup')
local event = require('nui.utils.autocmd').event

-- Tree data structure
M.layout = nil

-- Initialize tree module
function M.init(options)
    M.options = options
end

-- Create and show the tree popup
function M.toggle()
    if M.layout and M:layout_mounted() then
        M:hide()
        return
    end
    
    M:show()
end

-- Show the tree
function M.show()
    -- Calculate popup size
    local width = math.min(50, vim.o.columns - 4)
    local height = math.min(25, vim.o.lines - 4)
    
    -- Create popup
    M.layout = popup({
        enter = true,
        focusable = true,
        border = {
            style = "rounded",
            text = {
                top = " Ribbon Bookmarks ",
                top_align = "center",
            },
        },
        position = {
            row = 2,
            col = vim.o.columns - width - 2,
        },
        size = {
            width = width,
            height = height,
        },
    })
    
    -- Mount the popup
    M.layout:mount()
    
    -- Set buffer options
    vim.api.nvim_set_option_value('modifiable', true, {buf = M.layout.bufnr})
    vim.api.nvim_set_option_value('filetype', 'ribbon_tree', {buf = M.layout.bufnr})
    
    -- Render initial content
    M:_render()
    
    -- Set up key mappings in the tree buffer
    vim.keymap.set('n', '<CR>', function()
        M:_handle_jump()
    end, {buffer = M.layout.bufnr, silent = true, nowait = true})
    
    vim.keymap.set('n', 'd', function()
        M:_handle_delete()
    end, {buffer = M.layout.bufnr, silent = true, nowait = true})
    
    vim.keymap.set('n', 'e', function()
        M:_handle_annotate()
    end, {buffer = M.layout.bufnr, silent = true, nowait = true})
    
    vim.keymap.set('n', 'q', function()
        M:hide()
    end, {buffer = M.layout.bufnr, silent = true, nowait = true})
    
    vim.keymap.set('n', '<Esc>', function()
        M:hide()
    end, {buffer = M.layout.bufnr, silent = true, nowait = true})
    
    -- Auto-close when leaving buffer or pressing ESC
    M.layout:on(event.BufLeave, function()
        M:hide()
    end)
    
    -- Make buffer unmodifiable after initial render
    vim.api.nvim_set_option_value('modifiable', false, {buf = M.layout.bufnr})
end

-- Hide the tree
function M.hide()
    if M.layout then
        M.layout:unmount()
        M.layout = nil
    end
end

-- Check if layout is mounted
function M:layout_mounted()
    return self.layout and self.layout:mounted()
end

-- Render bookmarks in the tree
function M:_render()
    -- Access core module to get bookmarks
    local core_ok, core = pcall(require, 'ribbon.core')
    if not core_ok or not core or not core.bookmarks then
        vim.api.nvim_buf_set_lines(self.layout.bufnr, 0, -1, false, {"No bookmarks available"})
        vim.api.nvim_set_option_value('modifiable', false, {buf = self.layout.bufnr})
        return
    end
    
    local lines = {}
    table.insert(lines, " Ribbon Bookmarks ")
    table.insert(lines, string.rep("─", vim.api.nvim_win_get_width(0) - 2))
    
    local has_bookmarks = false
    
    -- Sort group names for consistent display
    local group_names = {}
    for group_name, _ in pairs(core.bookmarks) do
        table.insert(group_names, group_name)
    end
    table.sort(group_names)
    
    for _, group_name in ipairs(group_names) do
        local group = core.bookmarks[group_name]
        table.insert(lines, "  " .. group_name)
        if #group > 0 then
            has_bookmarks = true
            -- Sort bookmarks by filename and line for consistent display
            table.sort(group, function(a, b)
                if a.filename ~= b.filename then
                    return a.filename < b.filename
                end
                return a.line < b.line
            end)
            
            for _, bm in ipairs(group) do
                local indent = "    "
                local marker = bm.mnemonic and ("[" .. bm.mnemonic .. "] ") or "  "
                local filename_short = vim.fn.fnamemodify(bm.filename, ":t")
                local line_text = string.format("%s:%d", filename_short, bm.line + 1)
                
                local display_text = indent .. marker .. line_text
                if bm.annotation and bm.annotation ~= "" then
                    display_text = display_text .. "  -- " .. bm.annotation
                end
                table.insert(lines, display_text)
            end
        else
            table.insert(lines, "    (empty)")
        end
        table.insert(lines, "")  -- Empty line between groups
    end
    
    if not has_bookmarks then
        table.insert(lines, "  No bookmarks")
    end
    
    -- Remove trailing empty line
    if #lines > 0 and lines[#lines] == "" then
        table.remove(lines)
    end
    
    vim.api.nvim_buf_set_lines(self.layout.bufnr, 0, -1, false, lines)
    vim.api.nvim_set_option_value('modifiable', false, {buf = self.layout.bufnr})
end

-- Helper to get bookmark at screen line
function M:_get_bookmark_at_screen_line(screen_line)
    local core_ok, core = pcall(require, 'ribbon.core')
    if not core_ok or not core or not core.bookmarks then return nil end
    
    local lines = {}
    table.insert(lines, " Ribbon Bookmarks ")
    table.insert(lines, string.rep("─", vim.api.nvim_win_get_width(0) - 2))
    
    local line_index = 2  -- Start after header
    
    -- Sort group names for consistent display
    local group_names = {}
    for group_name, _ in pairs(core.bookmarks) do
        table.insert(group_names, group_name)
    end
    table.sort(group_names)
    
    for _, group_name in ipairs(group_names) do
        local group = core.bookmarks[group_name]
        -- Group name line
        if screen_line == line_index then
            return {type = "group", name = group_name}
        end
        line_index = line_index + 1
        
        if #group > 0 then
            -- Sort bookmarks
            table.sort(group, function(a, b)
                if a.filename ~= b.filename then
                    return a.filename < b.filename
                end
                return a.line < b.line
            end)
            
            for _, bm in ipairs(group) do
                if screen_line == line_index then
                    return {type = "bookmark", bm = bm, group = group_name}
                end
                line_index = line_index + 1
            end
        else
            -- Empty group line
            if screen_line == line_index then
                return {type = "empty_group", name = group_name}
            end
            line_index = line_index + 1
        end
        
        -- Empty line between groups
        if screen_line == line_index then
            return {type = "separator"}
        end
        line_index = line_index + 1
    end
    
    return nil
end

-- Handle jump to bookmark under cursor
function M:_handle_jump()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line_num = cursor[1]
    
    local item = self:_get_bookmark_at_screen_line(line_num)
    if not item or item.type ~= "bookmark" then
        vim.notify("Ribbon: Please position cursor on a bookmark entry", vim.log.levels.WARN)
        return
    end
    
    local bm = item.bm
    -- Resolve filename (may be stored or need to get from bufnr)
    local filename = bm.filename or (bm.bufnr and vim.api.nvim_buf_get_name(bm.bufnr) or '')
    if filename == '' then
        vim.notify("Ribbon: Cannot jump - buffer has no filename", vim.log.levels.ERROR)
        return
    end
    
    -- Open file and jump to line
    vim.cmd('edit ' .. vim.fn.fnameescape(filename))
    vim.api.nvim_win_set_cursor(0, {bm.line + 1, 0})
    M:hide()
end

-- Handle delete bookmark under cursor
function M:_handle_delete()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line_num = cursor[1]
    
    local item = self:_get_bookmark_at_screen_line(line_num)
    if not item or item.type ~= "bookmark" then
        vim.notify("Ribbon: Please position cursor on a bookmark entry", vim.log.levels.WARN)
        return
    end
    
    local core = require('ribbon.core')
    local item_bufnr = item.bm.bufnr
    local item_filename = item.bm.filename or (item_bufnr and vim.api.nvim_buf_get_name(item_bufnr) or '')
    -- Find and remove the bookmark
    local group = core.bookmarks[item.group]
    for i, bm in ipairs(group) do
        local bm_filename = bm.filename or (bm.bufnr and vim.api.nvim_buf_get_name(bm.bufnr) or '')
        if bm_filename == item_filename and bm.line == item.bm.line then
            table.remove(group, i)
            break
        end
    end
    
    -- Update UI
    require('ribbon.signs').render_all(core.bookmarks)
    require('ribbon.persistence').save(core)
    M:_render()  -- Refresh tree view
    
    vim.notify("Ribbon: Bookmark deleted", vim.log.levels.INFO)
end

-- Handle annotate bookmark under cursor
function M:_handle_annotate()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line_num = cursor[1]
    
    local item = self:_get_bookmark_at_screen_line(line_num)
    if not item or item.type ~= "bookmark" then
        vim.notify("Ribbon: Please position cursor on a bookmark entry", vim.log.levels.WARN)
        return
    end
    
    -- Store lookup info for async callback
    local item_filename = item.bm.filename or (item.bm.bufnr and vim.api.nvim_buf_get_name(item.bm.bufnr) or '')
    local item_line = item.bm.line
    local item_group = item.group
    
    -- Prompt for annotation
    vim.ui.input({
        prompt = 'Annotation: ',
        default = item.bm.annotation or ''
    }, function(input)
        if input ~= nil then  -- nil means user cancelled with Ctrl-C
            -- Find and update the bookmark by filename/line to avoid stale references
            local core = require('ribbon.core')
            local group = core.bookmarks[item_group]
            if group then
                for _, bm in ipairs(group) do
                    local bm_filename = bm.filename or (bm.bufnr and vim.api.nvim_buf_get_name(bm.bufnr) or '')
                    if bm_filename == item_filename and bm.line == item_line then
                        bm.annotation = input == '' and nil or input
                        break
                    end
                end
            end
            
            -- Update UI
            require('ribbon.signs').render_all(core.bookmarks)
            require('ribbon.persistence').save(core)
            M:_render()  -- Refresh tree view
        end
    end)
end

return M