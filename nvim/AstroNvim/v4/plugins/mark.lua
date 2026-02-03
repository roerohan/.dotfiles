-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
  'roerohan/mark.nvim',
  ft = 'markdown',
  build = 'cd typescript && bun install && bun run build',
  config = function()
    require('mark').setup({
    })
  end,
}
