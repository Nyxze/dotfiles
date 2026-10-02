vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.api.nvim_create_autocmd('VimLeave', {
  group = vim.api.nvim_create_augroup('OnExit', { clear = true }),
  desc = 'Restore default cursor',
  command = 'set guicursor=a:blinkwait700-blinkoff400-blinkon250-ver20',
})

vim.api.nvim_create_autocmd({ 'BufWinEnter' }, {
  group = vim.api.nvim_create_augroup('userconfig', { clear = true }),
  desc = 'return cursor to where it was last time closing the file',
  pattern = '*',
  command = 'silent! normal! g`"zv',
})
