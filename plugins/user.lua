return {
  -- You can also add new plugins here as well:
  -- Add plugins, the lazy syntax
  -- "andweeb/presence.nvim",
  -- {
  --   "ray-x/lsp_signature.nvim",
  --   event = "BufRead",
  --   config = function()
  --     require("lsp_signature").setup()
  --   end,
  -- },
  {
    "akinsho/pubspec-assist.nvim",
    dependencies = "plenary.nvim",
    lazy = true,
    event = { "BufRead pubspec.yaml" },
    opts = {},
  },
  -- {
  --   "epwalsh/pomo.nvim",
  --   lazy = true,
  --   cmd = { "TimerStart", "TimerRepeat" },
  --   dependencies = "rcarriga/nvim-notify",
  --   opts = {},
  -- },
  {
    "gaborvecsei/usage-tracker.nvim",
    lazy = true,
    event = { "BufEnter" },
    opts = { keep_eventlog_days = 30, inactivity_threshold_in_min = 1 },
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      window = {
        position = "right",
      },
    },
  },
  { "projectfluent/fluent.vim" },
  {
    "rebelot/heirline.nvim",
    opts = function(_, opts)
      local status = require "astronvim.utils.status"

      local trim = function(value) return string.gsub(value, "^%s*(.-)%s*$", "%1") end

      local stats_provider = function(self) return self.prefix .. self.stats end

      local waka_time_today = "0 secs"

      local waka_time_today_init = function(self)
        self.prefix = "󰄉 WT "
        self.stats = waka_time_today

        local waka_time_cli_location = trim(vim.fn.execute("WakaTimeCliLocation", "silent!"))

        if waka_time_cli_location == "" then return end

        local job = require "plenary.job"

        job
          :new({
            command = waka_time_cli_location,
            args = { "--today" },
            on_exit = function(j, _) waka_time_today = trim(j:result()[1]) end,
          })
          :start()

        self.stats = waka_time_today
      end

      local usage_tracker_init = function(self)
        self.prefix = "󰄉 UT "
        self.stats = "0 secs"

        local usage_tracker_daily = trim(vim.fn.execute("UsageTrackerShowDailyAggregation", "silent!"))
        local minutes_str = string.match(usage_tracker_daily, "%d+.%d+$")

        if minutes_str == nil then return end

        local minutes = tonumber(minutes_str)

        if minutes == nil then return end

        if minutes >= 60 then
          self.stats = string.format("%.2f", minutes / 60) .. " hours"
        elseif minutes >= 1 then
          self.stats = minutes_str .. " mins"
        else
          local seconds = (minutes * 60) / 100
          self.stats = string.format("%.2f", seconds) .. " secs"
        end
      end

      opts.statusline = { -- statusline
        hl = { fg = "fg", bg = "bg" },
        status.component.mode(),
        status.component.git_branch(),
        status.component.file_info { filetype = {}, filename = false, file_modified = false },
        status.component.git_diff(),
        status.component.diagnostics(),
        status.component.fill(),
        status.component.cmd_info(),
        status.component.fill(),
        { init = waka_time_today_init, provider = stats_provider, update = "BufEnter" },
        { provider = "  " },
        { init = usage_tracker_init, provider = stats_provider, update = "BufEnter" },
        { provider = " " },
        status.component.lsp(),
        status.component.treesitter(),
        status.component.nav(),
        status.component.mode { surround = { separator = "right" } },
      }

      opts.winbar = { -- winbar
        init = function(self) self.bufnr = vim.api.nvim_get_current_buf() end,
        fallthrough = false,
        { -- inactive winbar
          condition = function() return not status.condition.is_active() end,
          status.component.separated_path(),
          status.component.file_info {
            file_icon = { hl = status.hl.file_icon "winbar", padding = { left = 0 } },
            file_modified = false,
            file_read_only = false,
            hl = status.hl.get_attributes("winbarnc", true),
            surround = false,
            update = "BufEnter",
          },
        },
        { -- active winbar
          status.component.breadcrumbs { hl = status.hl.get_attributes("winbar", true) },
        },
      }

      opts.tabline = { -- tabline
        { -- file tree padding
          condition = function(self)
            self.winid = vim.api.nvim_tabpage_list_wins(0)[1]
            return status.condition.buffer_matches(
              { filetype = { "aerial", "dapui_.", "neo%-tree", "NvimTree" } },
              vim.api.nvim_win_get_buf(self.winid)
            )
          end,
          provider = function(self) return string.rep(" ", vim.api.nvim_win_get_width(self.winid) + 1) end,
          hl = { bg = "tabline_bg" },
        },
        status.heirline.make_buflist(status.component.tabline_file_info()), -- component for each buffer tab
        status.component.fill { hl = { bg = "tabline_bg" } }, -- fill the rest of the tabline with background color
        { -- tab list
          condition = function() return #vim.api.nvim_list_tabpages() >= 2 end, -- only show tabs if there are more than one
          status.heirline.make_tablist { -- component for each tab
            provider = status.provider.tabnr(),
            hl = function(self) return status.hl.get_attributes(status.heirline.tab_type(self, "tab"), true) end,
          },
          { -- close button for current tab
            provider = status.provider.close_button { kind = "TabClose", padding = { left = 1, right = 1 } },
            hl = status.hl.get_attributes("tab_close", true),
            on_click = {
              callback = function() require("astronvim.utils.buffer").close_tab() end,
              name = "heirline_tabline_close_tab_callback",
            },
          },
        },
      }

      opts.statuscolumn = { -- statuscolumn
        status.component.foldcolumn(),
        status.component.fill(),
        status.component.numbercolumn(),
        status.component.signcolumn(),
      }

      -- return the final configuration table
      return opts
    end,
  },
}
