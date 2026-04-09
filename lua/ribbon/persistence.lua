-- Persistence layer for ribbon bookmarks

local M = {}

-- Options from setup
M.options = {}

-- Initialize persistence
function M.init(options)
    M.options = options
    -- Ensure data directory exists
    vim.fn.mkdir(M.options.data_dir, 'p')
end

-- Save bookmarks to file
function M.save(core_module)
    -- Convert internal structure to serializable format
    local data = {}
    for group_name, group in pairs(core_module.bookmarks) do
        data[group_name] = {}
        for _, bm in ipairs(group) do
            -- Only save essential fields
            table.insert(data[group_name], {
                filename = vim.api.nvim_buf_get_name(bm.bufnr),
                line = bm.line,
                mnemonic = bm.mnemonic,
                annotation = bm.annotation
            })
        end
    end
    
    -- Create filename based on current working directory
    local cwd = vim.fn.getcwd()
    -- Use base64 encoding to avoid filesystem issues with special characters
    local fname = vim.base64.encode(cwd)
    local filepath = M.options.data_dir .. '/' .. fname .. '.json'
    
    -- Write JSON file
    local json = vim.fn.json_encode(data)
    local file = io.open(filepath, 'w')
    if file then
        file:write(json)
        file:close()
    end
end

-- Load bookmarks from file
function M.load(core_module)
    -- Get current working directory
    local cwd = vim.fn.getcwd()
    local fname = vim.base64.encode(cwd)
    local filepath = M.options.data_dir .. '/' .. fname .. '.json'
    
    -- Check if file exists
    if vim.fn.filereadable(filepath) == 0 then
        -- No existing bookmarks, initialize with empty Main group
        core_module.bookmarks = { Main = {} }
        return
    end
    
    -- Read and parse JSON
    local file = io.open(filepath, 'r')
    if not file then return end
    local content = file:read('*a')
    file:close()
    
    local success, data = pcall(vim.fn.json_decode, content)
    if not success or not data then
        core_module.bookmarks = { Main = {} }
        return
    end
    
    -- Convert loaded data to internal format
    core_module.bookmarks = {}
    for group_name, group in pairs(data) do
        core_module.bookmarks[group_name] = {}
        for _, bm in ipairs(group) do
            -- Validate required fields
            if bm.filename and bm.line ~= nil then
                table.insert(core_module.bookmarks[group_name], {
                    filename = bm.filename,
                    line = bm.line,
                    mnemonic = bm.mnemonic,
                    annotation = bm.annotation
                })
            end
        end
    end
    
    -- Ensure Main group exists
    if not core_module.bookmarks['Main'] then
        core_module.bookmarks['Main'] = {}
    end
end

return M