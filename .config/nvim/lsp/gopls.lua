return {
  cmd = { 'gopls' },
  filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
  on_attach = function()
    local c = require('vscode.colors').get_colors()
    vim.api.nvim_set_hl(0, '@lsp.typemod.type.interface.go', { fg = c.vscBlueGreen })
    vim.api.nvim_set_hl(0, '@lsp.type.keyword.go', { fg = c.vscPink })
  end,
  settings = {
    gopls = {
      gofumpt = true,
      codelenses = {
        gc_details = false,
        generate = true,
        regenerate_cgo = true,
        run_govulncheck = true,
        test = true,
        tidy = true,
        upgrade_dependency = true,
        vendor = true,
      },
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
      analyses = {
        nilness = true,
        unusedparams = true,
        unusedwrite = true,
        useany = true,
      },
      usePlaceholders = true,
      completeUnimported = true,
      staticcheck = true,
      directoryFilters = { '-.git', '-.vscode', '-.idea', '-.vscode-test', '-node_modules' },
      semanticTokens = true,
    },
  },
}
