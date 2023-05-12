-- Mapping data with "desc" stored directly by vim.keymap.set().
--
-- Please use this mappings table to set keyboard mapping since this is the
-- lower level configuration and more robust one. (which-key will
-- automatically pick-up stored data by this setting.)
return {
  -- first key is the mode
  n = {
    -- second key is the lefthand side of the map
    -- mappings seen under group name "Buffer"
    ["<leader>bn"] = { "<cmd>tabnew<cr>", desc = "New tab" },
    ["<leader>bD"] = {
      function()
        require("astronvim.utils.status").heirline.buffer_picker(
          function(bufnr) require("astronvim.utils.buffer").close(bufnr) end
        )
      end,
      desc = "Pick to close",
    },
    -- tables with the `name` key will be registered with which-key if it's installed
    -- this is useful for naming menus
    ["<leader>b"] = { name = "Buffers" },
    -- quick save
    -- ["<C-s>"] = { ":w!<cr>", desc = "Save File" },  -- change description but the same command

    ["n"] = { "nzzzv", desc = "Search next item and center." },
    ["N"] = { "Nzzzv", desc = "Search previous item and center." },

    ["<C-s>"] = { ":w!<cr>", desc = "Save File" },
    ["<C-`>"] = { "<cmd>ToggleTerm<cr>", desc = "Toggle terminal" },
    ["<C-u>"] = { "<C-u>zz", desc = "Half page up and center." },
    ["<C-d>"] = { "<C-d>zz", desc = "Half page down and center." },

    ["<leader>s"] = { [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], desc = "Replace current word." },
    ["<leader>u"] = { ":UndotreeToggle<cr>", desc = "Toggle undotree." },
  },
  t = {
    -- setting a mapping to false will disable it
    -- ["<esc>"] = false,
  },
  v = {
    ["J"] = { ":m '>+1<CR>gv=gv", desc = "Move chunk down." },
    ["K"] = { ":m '<-2<CR>gv=gv", desc = "Move chunk down." },
  },
}
