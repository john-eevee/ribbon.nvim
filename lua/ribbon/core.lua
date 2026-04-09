-- Core bookmark management logic

local M = {}

-- Options from setup
M.options = {}

-- Storage for bookmarks
-- Structure: { group = { {bufnr, line, mnemonic, annotation}, ... } }
M.bookmarks = {}

-- Initialize core module
function M.init(options)
    M.options = options
    -- Load persisted bookmarks
    require('ribbon.persistence').load(M)
end

-- Toggle an anonymous bookmark on current line
function M.toggle_bookmark()
    local bufnr = vim.api.nvim_get_current_buf()
    local line = vim.api.nvim_win_get_cursor(0)[1] - 1  -- 0-indexed
    local filename = vim.api.nvim_buf_get_name(bufnr)
    
    if filename == '' then return end  -- No name for unnamed buffers
    
    -- Check if bookmark already exists at this position
    local exists = false
    for _, group in pairs(M.bookmarks) do
        for _, bm in ipairs(group) do
            if bm.bufnr == bufnr and bm.line == line then
                -- Remove bookmark
                for i, b in ipairs(group) do
                    if b == bm then
                        table.remove(group, i)
                        exists = true
                        break
                    end
                end
                break
            end
        end
        if exists then break end
    end
    
    -- If not exists, add anonymous bookmark to default "Main" group
    if not exists then
        if not M.bookmarks['Main'] then
            M.bookmarks['Main'] = {}
        end
        table.insert(M.bookmarks['Main'], {
            bufnr = bufnr,
            line = line,
            mnemonic = nil,
            annotation = nil
        })
    end
    
    -- Update signs
    require('ribbon.signs').render_all(M.bookmarks)
    
    -- Persist changes
    require('ribbon.persistence').save(M)
end

-- Set or toggle a mnemonic bookmark (A-Z, 0-9)
function M.set_mnemonic_bookmark(char)
    if not char or char == '' then
        -- If no char provided, we could prompt, but for now just return
        return
    end
    
    -- Validate char is alphanumeric (A-Z, a-z, 0-9)
    if not char:match('^[%a%d]$') then
        vim.notify('Ribbon: Invalid mnemonic character. Use A-Z, a-z, or 0-9', vim.log.levels.WARN)
        return
    end
    
    local bufnr = vim.api.nvim_get_current_buf()
    local line = vim.api.nvim_win_get_cursor(0)[1] - 1  -- 0-indexed
    local filename = vim.api.nvim_buf_get_name(bufnr)
    
    if filename == '' then return end
    
    -- Remove any existing bookmark with this mnemonic in any group
    for group_name, group in pairs(M.bookmarks) do
        for i = #group, 1, -1 do  -- Iterate backwards for safe removal
            if group[i].mnemonic and group[i].mnemonic:lower() == char:lower() then
                table.remove(group, i)
            end
        end
    end
    
    -- Add bookmark to default group (or create it)
    if not M.bookmarks['Main'] then
        M.bookmarks['Main'] = {}
    end
    
    table.insert(M.bookmarks['Main'], {
        bufnr = bufnr,
        line = line,
        mnemonic = char:upper(),  -- Store as uppercase for consistency
        annotation = nil
    })
    
    -- Update signs
    require('ribbon.signs').render_all(M.bookmarks)
    
    -- Persist changes
    require('ribbon.persistence').save(M)
end

-- Jump to a mnemonic bookmark
function M.jump_to_bookmark(char)
    if not char or char == '' then
        vim.notify('Ribbon: No mnemonic specified', vim.log.levels.WARN)
        return
    end
    
    local target_mnemonic = char:upper()
    
    -- Search for bookmark with this mnemonic
    for group_name, group in pairs(M.bookmarks) do
        for _, bm in ipairs(group) do
            if bm.mnemonic == target_mnemonic then
                -- Resolve filename
                local filename = bm.filename
                if not filename and bm.bufnr then
                    filename = vim.api.nvim_buf_get_name(bm.bufnr)
                end
                
                if not filename or filename == '' then
                    vim.notify('Ribbon: Cannot jump - buffer has no filename', vim.log.levels.ERROR)
                    return
                end
                
                -- Open file and jump to line
                vim.cmd('edit ' .. vim.fn.fnameescape(filename))
                vim.api.nvim_win_set_cursor(0, {bm.line + 1, 0})
                return
            end
        end
    end
    
    vim.notify(string.format('Ribbon: No bookmark found for mnemonic "%s"', char), vim.log.levels.INFO)
end

-- Annotate the bookmark under cursor
function M.annotate_bookmark()
    local bufnr = vim.api.nvim_get_current_buf()
    local line = vim.api.nvim_win_get_cursor(0)[1] - 1  -- 0-indexed
    
    -- Find bookmark at this position
    local bookmark = nil
    local group_name = nil
    for gname, group in pairs(M.bookmarks) do
        for _, bm in ipairs(group) do
            if bm.bufnr == bufnr and bm.line == line then
                bookmark = bm
                group_name = gname
                break
            end
        end
        if bookmark then break end
    end
    
    if not bookmark then
        vim.notify('Ribbon: No bookmark at current line', vim.log.levels.WARN)
        return
    end
    
    -- Prompt for annotation
    vim.ui.input({
        prompt = 'Annotation: ',
        default = bookmark.annotation or ''
    }, function(input)
        if input ~= nil then  -- nil means user cancelled with Ctrl-C
            bookmark.annotation = input == '' and nil or input
            
            -- Update signs (annotation might affect display)
            require('ribbon.signs').render_all(M.bookmarks)
            
            -- Persist changes
            require('ribbon.persistence').save(M)
        end
    end)
end

-- Clear all bookmarks for current project
function M.clear_all_bookmarks()
    M.bookmarks = {}
    require('ribbon.signs').clear_all()
    require('ribbon.persistence').save(M)
end

return M