local ts_history = {}

local function select_node(node)
	local sr, sc, er, ec = node:range()
	local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
	vim.api.nvim_feedkeys(esc, "nx", false)
	vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
	vim.api.nvim_feedkeys("v", "nx", false)
	vim.api.nvim_win_set_cursor(0, { er + 1, math.max(0, ec - 1) })
end

vim.keymap.set("n", "<CR>", function()
	if vim.bo.buftype ~= "" then return end
	local node = vim.treesitter.get_node()
	if not node then return end
	ts_history = { node }
	select_node(node)
end, { desc = "Select treesitter node" })

vim.keymap.set("v", "<CR>", function()
	local last = ts_history[#ts_history]
	if not last then return end
	local parent = last:parent()
	if parent then
		table.insert(ts_history, parent)
		select_node(parent)
	end
end, { desc = "Expand treesitter selection" })

vim.keymap.set("v", "<BS>", function()
	if #ts_history > 1 then
		table.remove(ts_history)
		select_node(ts_history[#ts_history])
	else
		vim.cmd("normal! \27")
	end
end, { desc = "Shrink treesitter selection" })
