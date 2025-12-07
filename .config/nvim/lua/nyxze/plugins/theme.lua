local colors = {
  text = '#d4d4d4',
  peach = '#dcdcaa', -- functions
  blue = '#569cd6', -- classes/types
  teal = '#4ec9b0', -- properties
  mauve = '#c586c0', -- keywords/enums
  sky = '#9cdcfe', -- parameters
  red = '#f44747', -- builtins
  overlay1 = '#6a9955', -- comments
}
return {
  'catppuccin/nvim',
  name = 'catppuccin',
  priority = 1000,
  opts = {
    -- Override Catppuccin colors with VS Code Dark+ colors
    color_overrides = {
      mocha = {
        base = '#1E1E1E', -- editor background
        mantle = '#1E1E1E',
        crust = '#1E1E1E',

        -- UI colors
        text = '#D4D4D4',
        subtext1 = '#CCCCCC',
        subtext0 = '#858585',

        -- Syntax colors
        mauve = '#C586C0', -- keywords
        yellow = '#DCDCAA', -- functions
        peach = '#DCDCAA', -- alias for function/method
        sky = '#9CDCFE', -- variables
        green = '#6A9955', -- comments
        teal = '#4EC9B0', -- types
        blue = '#569CD6', -- constants
        red = '#E51400', -- VSCode error red
      },
    },

    custom_highlights = function(c)
      return {
        ------------------------------------------------------------------
        -- Core Editor
        ------------------------------------------------------------------
        Normal = { fg = c.text, bg = c.base },
        NormalFloat = { fg = c.text, bg = '#252526' }, -- floating windows

        CursorLine = { bg = '#2A2A2A' },
        CursorLineNr = { fg = '#D4D4D4', bold = true },

        LineNr = { fg = '#858585' },

        Visual = { bg = '#264F78' }, -- VSCode selection

        ------------------------------------------------------------------
        -- Neo-tree (matches VSCode sidebar)
        ------------------------------------------------------------------
        NeoTreeNormal = { fg = '#CCCCCC', bg = '#252526' },
        NeoTreeNormalNC = { fg = '#CCCCCC', bg = '#252526' },

        NeoTreeDirectoryName = { fg = '#9CDCFE' },
        NeoTreeDirectoryIcon = { fg = '#9CDCFE' },
        NeoTreeFileName = { fg = '#CCCCCC' },
        NeoTreeFileNameOpened = { fg = c.yellow },

        NeoTreeBorder = { fg = '#3C3C3C', bg = '#252526' },
        NeoTreeWinSeparator = { fg = '#3C3C3C' },
        ------------------------------------------------------------------
        -- Syntax (Treesitter)
        ------------------------------------------------------------------
        ['@comment'] = { fg = c.green },
        ['@keyword'] = { fg = c.mauve },
        ['@keyword.return'] = { fg = c.mauve },
        ['@module'] = { fg = '#f19216' },
        ['@namespace'] = { fg = '#f19216' },

        ['@string'] = { fg = '#CE9178' },
        ['@number'] = { fg = '#B5CEA8' },

        Function = { fg = c.yellow },
        ['@function'] = { fg = c.yellow },
        ['@function.call'] = { fg = c.yellow },
        ['@method'] = { fg = c.yellow },
        ['@method.call'] = { fg = c.yellow },

        ['@variable'] = { fg = c.sky },
        ['@variable.parameter'] = { fg = c.sky },

        ['@type'] = { fg = c.teal },
        Type = { fg = c.teal },
        ['@class'] = { fg = c.teal },
        ['@interface'] = { fg = c.teal },

        ['@constant'] = { fg = c.blue },
        ['@constant.builtin'] = { fg = c.blue },

        ------------------------------------------------------------------
        -- Semantic tokens (LSP)
        ------------------------------------------------------------------
        ['@lsp.type.function'] = { fg = c.yellow },
        ['@lsp.type.method'] = { fg = c.yellow },
        ['@lsp.type.property'] = { fg = c.sky },
        ['@lsp.type.class'] = { fg = c.teal },
        ['@lsp.type.variable'] = { fg = c.text },
      }
    end,
  },
}
