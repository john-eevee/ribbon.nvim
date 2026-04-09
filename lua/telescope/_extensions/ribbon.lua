-- Telescope extension for ribbon bookmarks

local M = {}

local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

-- Get bookmarks from ribbon core
local function get_bookmarks()
    local ok, ribbon = pcall(require, 'ribbon.core')
    if not ok or not ribbon or not ribbon.bookmarks then
        return {}
    end
    
    local results = {}
    for group_name, group in pairs(ribbon.bookmarks) do
        for _, bm in ipairs(group) do
            -- Resolve filename
            local filename = bm.filename
            if not filename and bm.bufnr then
                filename = vim.api.nvim_buf_get_name(bm.bufnr)
            end
            
            if not filename or filename == '' then
                goto continue
            end
            
            -- Get line text if buffer is loaded
            local text = ''
            if bm.bufnr and vim.api.nvim_buf_is_loaded(bm.bufnr) then
                text = vim.api.nvim_buf_get_lines(bm.bufnr, bm.line, bm.line + 1, false)[1] or ''
            end
            
            table.insert(results, {
                group = group_name,
                mnemonic = bm.mnemonic or '',
                filename = filename,
                lnum = bm.line + 1,
                text = text,
                annotation = bm.annotation or '',
                bufnr = bm.bufnr,
                line = bm.line
            })
            
            ::continue::
        end
    end
    return results
end

-- Main entry point for the telescope extension
function M.bookmarks(opts)
    opts = opts or {}
    
    local results = get_bookmarks()
    
    if vim.tbl_isempty(results) then
        vim.notify('Ribbon: No bookmarks found', vim.log.levels.INFO)
        return
    end
    
    pickers.new(opts, {
        prompt_title = 'Ribbon Bookmarks',
        finder = finders.new_table({
            results = results,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = function(entry)
                        local parts = {}
                        
                        -- Add group if not "Main"
                        if entry.group ~= "Main" then
                            table.insert(parts, string.format("[%s] ", entry.group))
                        end
                        
                        -- Add mnemonic if present
                        if entry.mnemonic ~= "" then
                            table.insert(parts, string.format("<%s> ", entry.mnemonic))
                        end
                        
                        -- Add filename:line
                        table.insert(parts, string.format("%s:%d ", vim.fn.fnamemodify(entry.filename, ":t"), entry.lnum))
                        
                        -- Add line text (truncated)
                        local text_preview = vim.fn.strcharpart(entry.text, 0, 30)
                        table.insert(parts, string.format("%-30s", text_preview))
                        
                        -- Add annotation if present
                        if entry.annotation ~= "" then
                            table.insert(parts, string.format("  -- %s", entry.annotation))
                        end
                        
                        return table.concat(parts)
                    end,
                    ordinal = entry.group .. " " .. 
                              (entry.mnemonic ~= "" and entry.mnemonic or " ") .. " " ..
                              vim.fn.fnamemodify(entry.filename, ":t") .. " " ..
                              entry.text .. " " ..
                              entry.annotation,  -- For fuzzy matching
                    lnum = entry.lnum,
                    bufnr = entry.bufnr,
                }
            end
        }),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
            -- Jump to bookmark on <CR>
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                if selection then
                    vim.cmd('edit ' .. vim.fn.fnameescape(selection.value.filename))
                    vim.api.nvim_win_set_cursor(0, {selection.value.lnum, 0})
                end
            end)
            
            -- Delete bookmark with 'd'
            map('i', 'd', function()
                local selection = action_state.get_selected_entry()
                if selection then
                    actions.close(prompt_bufnr)
                    local ribbon = require('ribbon.core')
                    local sel_filename = selection.value.filename
                    local sel_line = selection.value.line
                    -- Find and remove bookmark by filename and line
                    local group = ribbon.bookmarks[selection.value.group]
                    if group then
                        for i, bm in ipairs(group) do
                            local bm_filename = bm.filename or (bm.bufnr and vim.api.nvim_buf_get_name(bm.bufnr) or '')
                            if bm_filename == sel_filename and bm.line == sel_line then
                                table.remove(group, i)
                                break
                            end
                        end
                    end
                    -- Update UI
                    require('ribbon.signs').render_all(ribbon.bookmarks)
                    require('ribbon.persistence').save(ribbon)
                    vim.notify('Ribbon: Bookmark deleted', vim.log.levels.INFO)
                end
            end)
            
            -- Annotate bookmark with 'a'
            map('i', 'a', function()
                local selection = action_state.get_selected_entry()
                if selection then
                    actions.close(prompt_bufnr)
                    local ribbon = require('ribbon.core')
                    local sel_filename = selection.value.filename
                    local sel_line = selection.value.line
                    local sel_group = selection.value.group
                    
                    vim.ui.input({
                        prompt = 'Annotation: ',
                        default = selection.value.annotation or ''
                    }, function(input)
                        if input ~= nil then
                            -- Find and update bookmark by filename and line
                            local group = ribbon.bookmarks[sel_group]
                            if group then
                                for _, bm in ipairs(group) do
                                    local bm_filename = bm.filename or (bm.bufnr and vim.api.nvim_buf_get_name(bm.bufnr) or '')
                                    if bm_filename == sel_filename and bm.line == sel_line then
                                        bm.annotation = input == '' and nil or input
                                        break
                                    end
                                end
                            end
                            require('ribbon.signs').render_all(ribbon.bookmarks)
                            require('ribbon.persistence').save(ribbon)
                        end
                    end)
                end
            end)
            
            return true
        end,
    }):find()
end

return M