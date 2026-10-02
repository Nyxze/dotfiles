return {
  'stevearc/oil.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  lazy = false,
  keys = {
    { '<leader>e', '<cmd>Oil<CR>', desc = 'Open file explorer', silent = true },
  },
  opts = {
    default_file_explorer = true,
    view_options = {
      show_hidden = true,
    },
    float = {
      padding = 2,
    },
    keymaps = {
      ['<CR>'] = 'actions.select',
      ['-'] = 'actions.parent',
      ['_'] = 'actions.open_cwd',
      ['gs'] = 'actions.change_sort',
      ['g.'] = 'actions.toggle_hidden',
      ['<C-s>'] = false,
    },
  },
}
