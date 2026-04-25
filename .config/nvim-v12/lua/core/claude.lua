local function find_claude_pane()
	local session = vim.fn.system("tmux display-message -p '#{session_name}'"):gsub("\n", "")
	if session == "" then return nil, "Not inside tmux" end
	local panes = vim.fn.system("tmux list-panes -s -t " .. vim.fn.shellescape(session) .. " -F '#{session_name}:#{window_index}.#{pane_index} #{pane_pid}'")
	for line in panes:gmatch("[^\n]+") do
		local pane_id, shell_pid = line:match("^(%S+) (%d+)$")
		if shell_pid then
			local children = vim.fn.system("pgrep -P " .. shell_pid)
			for child_pid in children:gmatch("%d+") do
				local args = vim.fn.system("ps -p " .. child_pid .. " -o args="):gsub("\n", "")
				if args:match("claude") then return pane_id, nil end
			end
		end
	end
	return nil, "No claude pane found in session: " .. session
end

vim.g.claude_bell = vim.g.claude_bell ~= nil and vim.g.claude_bell or true

local function tmux_send(pane_id, text)
	local tmp = os.tmpname()
	local f = io.open(tmp, "w")
	f:write(text)
	f:close()
	vim.fn.system("tmux load-buffer " .. vim.fn.shellescape(tmp) .. " && tmux paste-buffer -t " .. vim.fn.shellescape(pane_id) .. " && tmux send-keys -t " .. vim.fn.shellescape(pane_id) .. " Enter")
	os.remove(tmp)
	if vim.g.claude_bell then
		local tty = vim.fn.system("tmux display-message -t " .. vim.fn.shellescape(pane_id) .. " -p '#{pane_tty}'"):gsub("\n", "")
		if tty ~= "" then vim.fn.system("printf '\\a' > " .. tty) end
	end
end

local function ask_claude(pane_id, context, notify_msg)
	vim.ui.input({ prompt = "Ask Claude: " }, function(question)
		if question == nil then return end
		local content = (question ~= "") and (question .. "\n\n" .. context) or context
		tmux_send(pane_id, content)
		vim.notify(notify_msg or "Sent to claude pane", vim.log.levels.INFO)
	end)
end

-- Send visual selection with file:line context
vim.keymap.set("v", "<leader>cq", function()
	local pane_id, err = find_claude_pane()
	if not pane_id then vim.notify(err, vim.log.levels.WARN) return end
	local start_line = vim.fn.line("v")
	local end_line = vim.fn.line(".")
	if start_line > end_line then start_line, end_line = end_line, start_line end
	local path = vim.fn.expand("%:p")
	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
	local context = path .. ":" .. start_line .. "-" .. end_line .. "\n" .. table.concat(lines, "\n")
	ask_claude(pane_id, context)
end, { desc = "Ask Claude about selection" })

-- Send enclosing function/class under cursor
vim.keymap.set("n", "<leader>cc", function()
	local pane_id, err = find_claude_pane()
	if not pane_id then vim.notify(err, vim.log.levels.WARN) return end
	local node = vim.treesitter.get_node()
	if not node then vim.notify("No treesitter node at cursor", vim.log.levels.WARN) return end
	local target_types = {
		function_declaration = true, function_definition = true, method_definition = true,
		arrow_function = true, local_function = true, method = true,
		class_declaration = true, class_definition = true,
	}
	while node and not target_types[node:type()] do
		node = node:parent()
	end
	if not node then vim.notify("No enclosing function or class found", vim.log.levels.WARN) return end
	local sr, _, er, ec = node:range()
	local lines = vim.api.nvim_buf_get_lines(0, sr, er + 1, false)
	if #lines > 0 then lines[#lines] = lines[#lines]:sub(1, ec) end
	local path = vim.fn.expand("%:p")
	local context = path .. ":" .. (sr + 1) .. "-" .. (er + 1) .. "\n" .. table.concat(lines, "\n")
	ask_claude(pane_id, context)
end, { desc = "Ask Claude about current function" })

-- Send current file path
vim.keymap.set("n", "<leader>cf", function()
	local pane_id, err = find_claude_pane()
	if not pane_id then vim.notify(err, vim.log.levels.WARN) return end
	ask_claude(pane_id, vim.fn.expand("%:p"))
end, { desc = "Ask Claude about file" })

-- Send diagnostics for current file
vim.keymap.set("n", "<leader>cx", function()
	local pane_id, err = find_claude_pane()
	if not pane_id then vim.notify(err, vim.log.levels.WARN) return end
	local diagnostics = vim.diagnostic.get(0)
	if #diagnostics == 0 then
		vim.notify("No diagnostics in this file", vim.log.levels.INFO)
		return
	end
	local path = vim.fn.expand("%:p")
	local lines = { path .. " diagnostics:" }
	local severity_names = { [1] = "ERROR", [2] = "WARN", [3] = "INFO", [4] = "HINT" }
	for _, d in ipairs(diagnostics) do
		local sev = severity_names[d.severity] or "?"
		table.insert(lines, string.format("  %s line %d: %s", sev, d.lnum + 1, d.message))
	end
	ask_claude(pane_id, table.concat(lines, "\n"), "Sent diagnostics to claude pane")
end, { desc = "Send diagnostics to Claude" })
