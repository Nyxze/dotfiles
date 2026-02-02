return {
  cmd = { 'pyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_markers = {
    'pyrightconfig.json',
    'pyproject.toml',
    'setup.py',
    'setup.cfg',
    'requirements.txt',
    'Pipfile',
    '.git',
  },
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = 'openFilesOnly',
      },
    },
  },
  on_attach = function(client, bufnr)
    vim.api.nvim_buf_create_user_command(bufnr, 'LspPyrightOrganizeImports', function()
      local params = {
        command = 'pyright.organizeimports',
        arguments = { vim.uri_from_bufnr(bufnr) },
      }
      client.request('workspace/executeCommand', params, nil, bufnr)
    end, {
      desc = 'Organize Imports',
    })
    vim.api.nvim_buf_create_user_command(bufnr, 'LspPyrightSetPythonPath', function(cmd)
      local path = cmd.args
      local clients = vim.lsp.get_clients {
        bufnr = vim.api.nvim_get_current_buf(),
        name = 'pyright',
      }
      for _, c in ipairs(clients) do
        if c.settings then
          c.settings.python = vim.tbl_deep_extend('force', c.settings.python --[[@as table]], { pythonPath = path })
        else
          c.config.settings = vim.tbl_deep_extend('force', c.config.settings, { python = { pythonPath = path } })
        end
        c:notify('workspace/didChangeConfiguration', { settings = nil })
      end
    end, {
      desc = 'Reconfigure pyright with the provided python path',
      nargs = 1,
      complete = 'file',
    })
  end,
}
