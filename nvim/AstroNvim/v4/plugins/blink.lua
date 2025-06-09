return { -- override blink.cmp plugin
  "Saghen/blink.cmp",
  version = "1.*",
  dependencies = {
    {
      'Exafunction/codeium.nvim',
    },
  },
  opts = {
    keymap = {
      ["<Tab>"] = { "snippet_forward", "fallback" },
    },
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer', 'codeium' },
      providers = {
        codeium = { name = 'Codeium', module = 'codeium.blink', async = true },
      },
    },
  },
}
