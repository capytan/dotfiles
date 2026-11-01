-- Disable markdown-preview.nvim, which the LazyVim markdown extra installs with its <leader>cp keymap.
-- Its bundled node 18 binary is outdated and upstream has been inactive since 2023; no preview replaces it.
return {
  { "iamcco/markdown-preview.nvim", enabled = false },
}
