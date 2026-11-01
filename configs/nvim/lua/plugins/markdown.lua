-- Drop markdown-toc, which the LazyVim markdown extra installs and registers as a formatter.
-- It is unused and unmaintained, and its toml dependency has unfixed vulnerabilities.
-- Removes in place so non-list keys (e.g. conform's stop_after_first) survive.
local function drop_toc(list)
  for i = #(list or {}), 1, -1 do
    if list[i] == "markdown-toc" then
      table.remove(list, i)
    end
  end
end

return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      drop_toc(opts.ensure_installed)
    end,
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      for _, formatters in pairs(opts.formatters_by_ft or {}) do
        if type(formatters) == "table" then
          drop_toc(formatters)
        end
      end
    end,
  },
}
