return {
  "saghen/blink.cmp",
  version = "1.*",
  opts = {
    keymap = {
      ["<Tab>"] = { "snippet_forward", "fallback" },
    },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },
  },
}
