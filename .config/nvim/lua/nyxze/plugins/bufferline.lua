return {
  'akinsho/bufferline.nvim',
  dependencies = 'nvim-tree/nvim-web-devicons',
  opts = {
    options = {
      numbers = 'ordinal',
      close_command = 'bdelete! %d',
      diagnostics = 'nvim_lsp',
      diagnostics_indicator = function(_, _, diag)
        local icons = { error = ' ', warning = ' ' }
        local ret = (diag.error and icons.error .. diag.error .. ' ' or '')
          .. (diag.warning and icons.warning .. diag.warning or '')
        return vim.trim(ret)
      end,
      modified_icon = '●',
      show_buffer_close_icons = true,
      show_close_icon = false,
      separator_style = 'slant',
      custom_filter = function(buf)
        return vim.api.nvim_buf_get_name(buf) ~= ''
      end,
    },
  },
}
