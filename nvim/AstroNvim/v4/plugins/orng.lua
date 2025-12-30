return {
  -- dir = "~/Documents/Repos/orng.nvim", -- local path
  "roerohan/orng.nvim", -- github repo
  lazy = false,
  priority = 1000,
  config = function()
    require("orng").setup({
      variant = "dark", -- "dark" or "light"
      transparent = false,
      italic_comment = false,
    })
    -- vim.cmd("colorscheme orng")
  end,
}
