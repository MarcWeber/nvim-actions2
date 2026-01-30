--[[
simple graph based runner.
Each run steps has wait_for dependencies.
Done steps get removed also from wait_for

task = {
  steps = {
  1: {
    wait_for: {}
    command: ...
  }
  2: {
    wait_for: {1}
    command: ...
  }
}

command : either viml expression or function (continuation) .. end block
--]]



local M = {}
M.state = {}
M.last_id = 0

--- @param type "c"|"l" The list type: 'c' for quickfix, 'l' for location
function M.has_real_issues(type)
  -- Determine the getter and the close command
  local get_list = type == "c" and vim.fn.getqflist or function() return vim.fn.getloclist(0) end
  local items = get_list()
  for _, item in ipairs(items) do
    if item.bufnr > 0 then
      return true
    end
  end
  return false
end

function M.auto_open_close(t)
  local hri = M.has_real_issues(t)
  local list_impl = M.list_implementations[t]
  if hri then
    list_impl.open()
  else
    list_impl.close()
  end
end

M.list_implementations = {
  c = {
    open = function() vim.cmd("copen") end,
    close = function() vim.cmd("cclose") end,
    set = function(what) vim.fn.setqflist({}, " ", what) end,
    get = function() return vim.getqflist() end,
    auto_open_close = function() M.auto_open_close("c") end
  },
  l = {
    open = function()  vim.cmd("lopen") end,
    close = function() vim.cmd("lclose") end,
    set = function(what) vim.setloclist({}, " ", what) end,
    get = function() return vim.fn.getloclist() end,
    auto_open_close = function() auto_open_close("l") end
  }
}

-- Helper to expand VimL-style arguments dynamically
local function resolve_args(cmd_parts)
  local resolved = {}
  for _, part in ipairs(cmd_parts) do
    if type(part) == 'function' then
      table.insert(resolved, part())
    else
      table.insert(resolved, part)
    end
  end
  return resolved
end

function M.list_to_graph(steps)
  -- {"viml", fun .. end, "viml"}
  local step_map = {}
  for i, c in ipairs(steps) do
    if c == nil then break end
    local s = {
      command = c
    }
    if i > 1 then
      s.wait_for = {i - 1} -- Dependency is now a numeric ID
    end
    step_map[i] = s
  end
  return { steps = step_map }
end

function M.run_graph(graph)
  M.last_id = M.last_id + 1
  M.state[M.last_id] = graph
  M.next(M.last_id, true)
end

function M.run_list(list)
  M.run_graph(M.list_to_graph(list))
end

local function run_step(run_id, step_id)
  local cmd = M.state[run_id].steps[step_id].command
  local continuation = function(success)
    M.next(run_id, success, step_id)
  end
  if type(cmd) == 'string' then
    vim.cmd(cmd)
    continuation(true)
    return
  end
  if type(cmd) == 'function' then
    cmd(continuation)
    return
  end
end

-- removes the completed step_id also from wait_for generating steps_ready
-- starts steps_ready 
function M.next(run_id, success, completed_step_id)
  local run = M.state[run_id]

  if not success or not run then
    M.state[run_id] = nil
    return
  end

  local steps_ready = {}

  if completed_step_id then
    -- remove the step which is completed
    run.steps[completed_step_id] = nil
  end

  for id, step in pairs(run.steps) do
    if step.wait_for then
      table.remove(step.wait_for, completed_step_id)
    end
    if not step.wait_for or not next(step.wait_for) then
      table.insert(steps_ready, id)
    end
  end

  for _, step_id in ipairs(steps_ready) do
    run_step(run_id, step_id) -- this might remove steps in non async case so must be done when iteration is complete otherwise steps might get missed!
  end

  if not next(run.steps) then
    M.state[run_id] = nil
  end
end

function M.run_populate_list_step(shell_command, opts)
  return function(continuation)
    local cmd = shell_command
    if type(cmd) == 'table' then cmd = resolve_args(cmd) end
    if type(cmd) == 'function' then cmd = cmd() end

    list_type = opts[list_type] or "c"
    local list_impl = M.list_implementations[list_type]

    -- 3. Asynchronous Execution (vim.system)
    vim.system(cmd, { text = true }, function(obj)
      vim.schedule(function()
        local success = obj.code == 0
        local output = obj.stdout or ""

        if success or output ~= "" then
          -- 4. Quickfix Population (I/O related, stays here)
          local lines = vim.split(output, "\n")
          local qf_opts = {
            lines = lines,
            efm = opts.efm,
            title = type(cmd) == 'table' and cmd[1] or cmd
          }
          list_impl.set(qf_opts)

          list_impl.open()
          if not opts.no_auto_open_close then
            list_impl.auto_open_close(list_type)
          end
        end
        -- 5. Signal completion and result to the central state machine.
        continuation(success)
      end)
    end)
  end
end

function M.run_to_list(shell_command, opts, then_)
  -- runs the shell_command then feeds the result into quicklist/locationlist {list_type = "l"}
  -- opens if there are error lines otherwise closes see no_auto_open_close
  -- then optional action eg show pdf
  M.run_list({M.run_populate_list_step(shell_command, opts), then_})
end

function M.map_efm_cmd_run(description, key, ...)
  if #args == 1 then
    args = vim.fn.split(args[0], " ")
  end
  vim.keymap.set('n', key, efm_cmd_run(unpack(arg)), { silent = true, desc = 'Run zig build' })
end

return M
