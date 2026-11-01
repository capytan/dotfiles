local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local function fail(msg, out)
    vim.api.nvim_echo({
      { msg .. "\n", "ErrorMsg" },
      { out or "", "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end

  -- Clone lazy.nvim at the commit pinned in lazy-lock.json instead of the moving `stable` tag.
  -- Plugin installs already follow the lockfile, but lazy.nvim itself is never reinstalled.
  local lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json"
  local ok, commit = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(lockfile), "\n"))["lazy.nvim"].commit
  end)
  if not ok or type(commit) ~= "string" or not commit:match("^%x+$") then
    fail("No valid lazy.nvim commit in " .. lockfile)
  end

  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--no-checkout", lazyrepo, lazypath })
  if vim.v.shell_error == 0 then
    out = vim.fn.system({ "git", "-C", lazypath, "checkout", "--quiet", commit })
  end
  if vim.v.shell_error ~= 0 then
    -- Leaving a partial clone would make the next start skip this bootstrap and run it unpinned
    vim.fn.delete(lazypath, "rf")
    fail("Failed to clone lazy.nvim at " .. commit .. ":", out)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- add LazyVim and import its plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- import/override with your plugins
    { import = "plugins" },
  },
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = {
    enabled = true, -- check for plugin updates periodically
    notify = false, -- notify on update
  }, -- automatically check for plugin updates
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
