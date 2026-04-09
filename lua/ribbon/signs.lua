-- Sign management for ribbon bookmarks

local M = {}

-- Options from setup
M.options = {}

-- Namespace for our signs
M.ns_id = vim.api.nvim_create_namespace('ribbon_signs')

-- Buffer -> {extmark_id -> bookmark_ref} mapping for tracking
M.extmarks = {}

-- Initialize signs module
function M.init(options)
    M.options = options
    M.setup_highlights()
end

-- Render all bookmarks as signs/extmarks
function M.render_all(bookmarks)
    -- Clear existing marks first
    M.clear_all()
    
    -- Reorganize bookmarks by filename for efficient rendering
    local buf_bookmarks = {}
    for group_name, group in pairs(bookmarks) do
        for _, bm in ipairs(group) do
            -- Resolve filename
            local filename = bm.filename
            if not filename and bm.bufnr then
                filename = vim.api.nvim_buf_get_name(bm.bufnr)
            end
            if not filename or filename == '' then
                goto continue
            end
            
            if not buf_bookmarks[filename] then
                buf_bookmarks[filename] = {}
            end
            table.insert(buf_bookmarks[filename], bm)
            
            ::continue::
        end
    end
    
    -- Render bookmarks for each buffer
    for filename, bms in pairs(buf_bookmarks) do
        local bufnr = vim.fn.bufadd(filename)
        if bufnr ~= 0 then
            vim.fn.bufload(bufnr)  -- Ensure buffer is loaded before setting extmarks
            for _, bm in ipairs(bms) do
                local text = bm.mnemonic or (M.options and M.options.sign_text or '■')
                local hl_group = bm.mnemonic and 'RibbonMnemonic' or 'RibbonAnonymous'
                
                local extmark_id = vim.api.nvim_buf_set_extmark(bufnr, M.ns_id, 
                    bm.line, 0, {
                    virt_text = {{text, hl_group}},
                    virt_text_pos = 'overlay',
                    priority = M.options and M.options.sign_priority or 10,
                })
                
                -- Track the extmark for potential updates/deletion
                if not M.extmarks[bufnr] then
                    M.extmarks[bufnr] = {}
                end
                M.extmarks[bufnr][extmark_id] = bm
            end
        end
    end
end

-- Clear all ribbon signs/extmarks
function M.clear_all()
    for bufnr, extmark_table in pairs(M.extmarks) do
        for extmark_id, _ in pairs(extmark_table) do
            pcall(vim.api.nvim_buf_del_extmark, bufnr, M.ns_id, extmark_id)
        end
    end
    M.extmarks = {}
end

-- Helper to set up highlight groups
function M.setup_highlights()
    vim.api.nvim_set_hl(0, 'RibbonMnemonic', {bold = true, fg = '#ff9e64'})
    vim.api.nvim_set_hl(0, 'RibbonAnonymous', {fg = '#89ddff'})
end

return M