local M = {}

-- Default trigger to start the binding process
-- vim.keymap.set('n', '<F4>', require('nvim-actions2-demo').select_action2, { desc = "Setup Compilation Action" })

M.demos = [[
noremap <silent> <F4> <Cmd>lua require('nvim-actions2').run_to_list({'./gradlew'}, efm("clang"))<CR>
run_to_list({'./gradlew'}, efm('cpp') )
run_to_list({'./gradlew', 'installDebug'}, efm('gradle clang java kotlin'))
run_to_list({'cargo', 'ndk', '-t', 'arm64-v8a', '-o', 'app/src/main/jniLibs/', 'build'}, efm('rust-errors-only') )
run_to_list({'cargo', 'ndk', '-t', 'arm64-v8a', '-o', 'app/src/main/jniLibs/', 'build'}, efm('rust') )
run_to_list({'cargo', 'apk', 'build'}, efm('rust-errors-only') )
run_to_list({'cargo', 'apk', 'run'}, efm('rust-errors-only') )
run_to_list({'cargo', 'build'}, efm('rust') )
run_to_list({'cargo', 'run'}, efm('rust') )
run_to_list({'cargo', 'run'}, efm('rust-errors-only') )
run_to_list({'cargo', 'build'}, efm('rust-errors-only') )
run_to_list({'cargo', 'build', '--release'}}, efm('rust') )
run_to_list({'bash', `vim.fn.expand('%')`}, {efm = "%f:%l"})
]]

local function bind_and_run(choice, key, env)
  -- env: vars which are available when evaling the line eg run_to_list gets bound
  if not choice or not key or key == "" then return end

  -- Function to handle the actual execution logic
  local function mapping_callback()
    local actions2 = require('nvim-actions2')
    
    -- 1. Identify backtick expressions and pre-evaluate them
    local results = {}
    local i = 0
    -- Replace `code` with a placeholder variable name like __var1, __var2
    local sanitized_choice = choice:gsub("`([^`]+)`", function(code)
      i = i + 1
      local var_name = "__var" .. i
      local func = load("return " .. code)
      if func then
        env[var_name] = func() -- Store the actual result (string, table, etc.) in env
      end
      return var_name -- Put the variable name into the string instead of the value
    end)

    -- 2. Run the sanitized string with the populated environment
    local run_cmd, err = load("return " .. sanitized_choice, nil, "t", env)
    if run_cmd then
      local success, run_err = pcall(run_cmd)
      if not success then print("Runtime Error: " .. run_err) end
    else
      print("Load Error: " .. err)
    end
  end
  -- Bind and execute
  vim.keymap.set('n', key, mapping_callback, { desc = "Mapped: " .. choice })
  print(string.format("Bound to %s.", key))
  mapping_callback()
end
function M.select_action2()
  local lines = vim.split(M.demos, "\n", { trimempty = true })
  local actions2 = require('nvim-actions2')
  local env = setmetatable(
    -- or just actions2, keeping explicit list so that you can customize
    {
    efm_from_keys = vim.fn['vim_addon_errorformats#ForList'],
    efm = function(keys) return {efm = vim.fn['vim_addon_errorformats#ForList']} end,
    run_to_list = actions2.run_to_list,
    run_populate_list_step = actions2.run_populate_list_step,
    run_graph = actions2.run_graph
    }, { __index = _G })
  M.select(lines, env)
end
function M.select(lines, env)
  local ok, telescope = pcall(require, "telescope.pickers")

  local function prompt_for_key(choice)
    vim.ui.input({ prompt = 'Bind action to key (e.g. <F4>): ', default = '<F4>' }, function(key)
      bind_and_run(choice, key, env)
    end)
  end

  if ok then
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    telescope.new({}, {
      prompt_title = "Select Action to Bind",
      finder = finders.new_table({ results = lines }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()[1]
          actions.close(prompt_bufnr)
          prompt_for_key(selection)
        end)
        return true
      end,
    }):find()
  else
    vim.ui.select(lines, { prompt = 'Select Action to Bind:' }, function(choice)
      if choice then prompt_for_key(choice) end
    end)
  end
end

return M
