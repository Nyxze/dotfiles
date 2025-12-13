return {
  'mfussenegger/nvim-dap',
  dependencies = {
    {
      'mason-org/mason.nvim',
      opts = function(_, opts)
        opts.ensure_installed = opts.ensure_installed or {}
        table.insert(opts.ensure_installed, 'js-debug-adapter')
      end,
    },
  },
  opts = function()
    local dap = require 'dap'
    for _, adType in ipairs { 'node', 'chrome' } do
      local pwaT = 'pwa-' .. adType
      if not dap.adapters[pwaT] then
        dap.adapters[pwaT] = {
          type = 'server',
          host = 'localhost',
          port = '${port}',
          executable = {
            command = 'js-debug-adapter',
            args = { '${port}' },
          },
        }
      end

      if not dap.adapters[adType] then
        dap.adapters[adType] = function(cb, cfg)
          local native = dap.adapters[pwaT]
          cfg.type = pwaT
          if type(native) == 'function' then
            native(cb, cfg)
          else
            cb()
          end
        end
      end
    end

    local js_files = { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact' }
    local vscode = require 'dap.ext.vscode'
    vscode.type_to_filetype['node'] = js_files
    vscode.type_to_filetype['pwa-node'] = js_files
    for _, lang in ipairs(js_files) do
      if not dap.configurations[lang] then
        local runtimeExec = nil
        if lang:find 'typescript' then
          runtimeExec = vim.fn.executable 'tsx' == 1 and 'tsx' or 'ts-node'
        end
        dap.configurations[lang] = {
          {
            type = 'pwa-node',
            request = 'launch',
            name = 'Launch file',
            program = '${file}',
            cwd = '${workspaceFolder}',
            sourceMaps = true,
            runtimeExecutable = runtimeExec,
            skipFiles = {
              '<node_internals>/**',
              'node_modules/**',
            },
            resolveSourceMapLocation = {
              '${worspaceFolder}/**',
              '!**/node_modules/**',
            },
          },
          {
            type = 'pwa-node',
            request = 'attach',
            name = 'Attach',
            processId = require('dap.utils').pick_process,
            cwd = '${workspaceFolder}',
            sourceMaps = true,
            runtimeExecutable = runtimeExec,
            skipFiles = {
              '<node_internals>/**',
              'node_modules/**',
            },
            resolveSourceMapLocation = {
              '${worspaceFolder}/**',
              '!**/node_modules/**',
            },
          },
        }
      end
    end
  end,
}
