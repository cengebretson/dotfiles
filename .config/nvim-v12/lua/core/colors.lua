local ok, catppuccin = pcall(require, "catppuccin.palettes")
local p = ok and catppuccin.get_palette("mocha") or {}

return {
	-- statusline
	statusline_bg = p.surface0,  -- lualine section backgrounds
	mode_fg       = p.flamingo,  -- mode indicator
	branch_fg     = p.green,     -- git branch
	separator_fg  = p.overlay2,  -- separator icons
	cursor_fg     = p.red,       -- cursor position
	filename_fg   = p.blue,      -- filename
	lsp_fg        = p.yellow,    -- LSP client names / progress
	diff_add      = p.teal,      -- git diff added
	diff_mod      = p.yellow,    -- git diff modified
	diff_del      = p.red,       -- git diff removed
	diag_error    = p.red,
	diag_warn     = p.yellow,
	diag_info     = p.blue,
	diag_hint     = p.teal,

	-- tabline / statuscolumn
	accent        = p.blue,      -- current line number, active tab
	line_nr       = p.overlay1,  -- inactive line numbers
	tab_inactive  = p.overlay0,  -- inactive tab text
	tab_sep       = p.surface1,  -- tab separator

	-- floats
	-- catppuccin's real mocha base; hardcoded because themes.lua overrides
	-- p.base to #000000 for terminal transparency. Used for floats that must
	-- stay readable (e.g. Mason).
	float_bg      = "#1e1e2e",
}
