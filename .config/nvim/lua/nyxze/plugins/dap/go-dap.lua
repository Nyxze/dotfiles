return {
  'leoluz/nvim-dap-go',
  ft = 'go', -- Only load this plugin for Go files
  dependencies = {
    'mfussenegger/nvim-dap', -- Ensure DAP is loaded first
  },
  config = function(_, opts)
    require('dap-go').setup(opts)
  end,
}
