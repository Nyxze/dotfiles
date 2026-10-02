local dap = require 'dap'
local dap_python = require 'dap-python'

-- 1. Path to the python executable managed by Mason
-- This assumes you installed 'debugpy' via Mason
local debugpy_path = vim.fn.stdpath 'data' .. '/mason/packages/debugpy/venv/bin/python'
dap_python.setup(debugpy_path)

-- 2. Add Flask to the Python configurations
table.insert(dap.configurations.python, {
  type = 'python',
  request = 'launch',
  name = 'Flask: Run app.py',
  module = 'flask',
  env = {
    FLASK_APP = 'app.py', -- Adjust this to your entry point (e.g., 'wsgi.py' or 'src/app')
    FLASK_DEBUG = '0', -- MUST be 0/false for DAP to work correctly
    FLASK_ENV = 'development',
  },
  args = {
    'run',
    '--no-debugger', -- Disable Flask's built-in browser debugger
    '--no-reload', -- Disable auto-reload (reloader kills the debug session)
  },
  jinja = true, -- Enables debugging of Jinja2 templates if needed
  pythonPath = function()
    -- Use the project's virtual environment if it exists
    local cwd = vim.fn.getcwd()
    if vim.fn.executable(cwd .. '/venv/bin/python') == 1 then
      return cwd .. '/venv/bin/python'
    elseif vim.fn.executable(cwd .. '/.venv/bin/python') == 1 then
      return cwd .. '/.venv/bin/python'
    else
      return 'python'
    end
  end,
})
