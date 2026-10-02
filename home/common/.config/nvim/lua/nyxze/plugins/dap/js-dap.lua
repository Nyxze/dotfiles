local dap = require 'dap'
for _, adapter in ipairs { 'node', 'chrome', 'msedge' } do
  local native_adapter = 'pwa-' .. adapter

  -- Main adapter
  dap.adapters[native_adapter] = {
    type = 'server',
    host = 'localhost',
    port = '${port}',
    executable = {
      command = 'js-debug-adapter',
      args = { '${port}' },
    },
    enrich_config = function(config, on_config)
      config.type = native_adapter
      on_config(config)
    end,
  }
  -- Map to native adapter
  dap.adapters[adapter] = dap.adapters[native_adapter]
end

local js_languages = { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact' }
for _, language in ipairs(js_languages) do
  dap.configurations[language] = {
    {
      type = 'pwa-node',
      request = 'launch',
      name = 'Launch Current File (pwa-node)',
      program = '${file}',
      cwd = '${workspaceFolder}',
      runtimeExecutable = function()
        if vim.fn.executable 'tsx' == 1 then
          return 'tsx'
        elseif vim.fn.executable 'ts-node' == 1 then
          return 'ts-node'
        else
          return 'node'
        end
      end,
      sourceMaps = true,
      protocol = 'inspector',
      skipFiles = { '<node_internals>/**', 'node_modules/**' },
      resolveSourceMapLocation = {
        '${workspaceFolder}/**',
        '!**/node_modules/**',
      },
    },
    {
      type = 'pwa-node',
      request = 'attach',
      name = 'Attach to Process',
      processId = require('dap.utils').pick_process,
      cwd = '${workspaceFolder}',
      sourceMaps = true,
    },
    {
      type = 'pwa-node',
      request = 'launch',
      name = 'Debug Jest Tests',
      -- trace = true, -- unlock this to debug the debugger
      runtimeExecutable = 'node',
      runtimeArgs = {
        './node_modules/jest/bin/jest.js',
        '--runInBand',
      },
      rootPath = '${workspaceFolder}',
      cwd = '${workspaceFolder}',
      console = 'integratedTerminal',
      internalConsoleOptions = 'neverOpen',
    },
  }
end
