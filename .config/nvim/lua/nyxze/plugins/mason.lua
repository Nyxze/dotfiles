return {
  'mason-org/mason.nvim',
  lazy = false, -- Load immediately so the :Mason command is always available
  config = true, -- Runs require("mason").setup()
}
