return {
  'rcarriga/nvim-dap-ui',
  dependencies = {
    'nvim-neotest/nvim-nio',
  },
  opts = {
    controls = {
      element = 'repl',
      enabled = true,
      icons = {
        pause = '⏸',
        play = '▶',
        step_into = '⏎',
        step_over = '⏭',
        step_out = '⏮',
        step_back = 'b',
        run_last = '▶▶',
        terminate = '⏹',
        disconnect = '⏏',
      },
    },
  },
  keys = {
    {
      '<leader>du',
      function()
        require('dapui').toggle {}
      end,
      desc = 'Dap UI',
    },
    {
      '<leader>de',
      function()
        require('dapui').eval()
      end,
      desc = 'Eval',
      mode = { 'n', 'x' },
    },
  },
}
