-- Find a pane running an AI CLI (claude preferred, codex fallback)
-- Returns pane_id, tool_name, err
local function child_pids(pid)
	local output = vim.fn.system("pgrep -P " .. vim.fn.shellescape(pid))
	local pids = {}
	for child in output:gmatch("%d+") do
		table.insert(pids, child)
	end
	return pids
end

local function find_ai_process(root_pid)
	local stack = { root_pid }
	while #stack > 0 do
		local pid = table.remove(stack)
		local args = vim.fn.system("ps -p " .. vim.fn.shellescape(pid) .. " -o args="):gsub("\n", " ")
		local lower_args = args:lower()
		if lower_args:match("claude") then
			return "claude"
		elseif lower_args:match("codex") then
			return "codex"
		end

		for _, child in ipairs(child_pids(pid)) do
			table.insert(stack, child)
		end
	end
end

local function find_ai_pane()
	local session = vim.fn.system("tmux display-message -p '#{session_name}'"):gsub("\n", "")
	if session == "" then
		return nil, nil, "Not inside tmux"
	end
	local panes = vim.fn.system(
		"tmux list-panes -s -t "
			.. vim.fn.shellescape(session)
			.. " -F '#{session_name}:#{window_index}.#{pane_index} #{pane_pid}'"
	)
	local claude_pane, codex_pane
	for line in panes:gmatch("[^\n]+") do
		local pane_id, shell_pid = line:match("^(%S+) (%d+)$")
		if shell_pid then
			local tool = find_ai_process(shell_pid)
			if tool == "claude" then
				claude_pane = pane_id
			elseif tool == "codex" then
				codex_pane = pane_id
			end
		end
		if claude_pane then
			break
		end
	end
	if claude_pane then
		return claude_pane, "claude", nil
	end
	if codex_pane then
		return codex_pane, "codex", nil
	end
	return nil, nil, "No claude or codex pane found in session: " .. session
end

if vim.g.ai_bell == nil then
	vim.g.ai_bell = vim.g.claude_bell ~= nil and vim.g.claude_bell or true
end

local function tmux_send(pane_id, text)
	local tmp = os.tmpname()
	local f = io.open(tmp, "w")
	if not f then
		vim.notify("Could not create temp file for tmux send", vim.log.levels.ERROR)
		return
	end
	f:write(text)
	f:close()
	vim.fn.system(
		"tmux load-buffer "
			.. vim.fn.shellescape(tmp)
			.. " && tmux paste-buffer -t "
			.. vim.fn.shellescape(pane_id)
			.. " && tmux send-keys -t "
			.. vim.fn.shellescape(pane_id)
			.. " Enter"
	)
	os.remove(tmp)
	if vim.g.ai_bell then
		local tty = vim.fn
			.system("tmux display-message -t " .. vim.fn.shellescape(pane_id) .. " -p '#{pane_tty}'")
			:gsub("\n", "")
		if tty ~= "" then
			vim.fn.system("printf '\\a' > " .. tty)
		end
	end
end

local function ask_ai(pane_id, tool, context, notify_msg)
	vim.ui.input({ prompt = "Ask " .. tool .. ": " }, function(question)
		if question == nil then
			return
		end
		local content = (question ~= "") and (question .. "\n\n" .. context) or context
		tmux_send(pane_id, content)
		vim.notify(notify_msg or ("Sent to " .. tool .. " pane"), vim.log.levels.INFO)
	end)
end

-- Send visual selection with file:line context
vim.keymap.set("v", "<leader>cq", function()
	local pane_id, tool, err = find_ai_pane()
	if not pane_id then
		vim.notify(err, vim.log.levels.WARN)
		return
	end
	local start_line = vim.fn.line("v")
	local end_line = vim.fn.line(".")
	if start_line > end_line then
		start_line, end_line = end_line, start_line
	end
	local path = vim.fn.expand("%:p")
	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
	local context = path .. ":" .. start_line .. "-" .. end_line .. "\n" .. table.concat(lines, "\n")
	ask_ai(pane_id, tool, context)
end, { desc = "Ask AI about selection" })

-- Send enclosing function/class under cursor
vim.keymap.set("n", "<leader>cc", function()
	local pane_id, tool, err = find_ai_pane()
	if not pane_id then
		vim.notify(err, vim.log.levels.WARN)
		return
	end
	local node = vim.treesitter.get_node()
	if not node then
		vim.notify("No treesitter node at cursor", vim.log.levels.WARN)
		return
	end
	local target_types = {
		function_declaration = true,
		function_definition = true,
		method_definition = true,
		arrow_function = true,
		local_function = true,
		method = true,
		class_declaration = true,
		class_definition = true,
	}
	while node and not target_types[node:type()] do
		node = node:parent()
	end
	if not node then
		vim.notify("No enclosing function or class found", vim.log.levels.WARN)
		return
	end
	local sr, _, er, ec = node:range()
	local lines = vim.api.nvim_buf_get_lines(0, sr, er + 1, false)
	if #lines > 0 then
		lines[#lines] = lines[#lines]:sub(1, ec)
	end
	local path = vim.fn.expand("%:p")
	local context = path .. ":" .. (sr + 1) .. "-" .. (er + 1) .. "\n" .. table.concat(lines, "\n")
	ask_ai(pane_id, tool, context)
end, { desc = "Ask AI about current function" })

-- Send current file path
vim.keymap.set("n", "<leader>cf", function()
	local pane_id, tool, err = find_ai_pane()
	if not pane_id then
		vim.notify(err, vim.log.levels.WARN)
		return
	end
	ask_ai(pane_id, tool, vim.fn.expand("%:p"))
end, { desc = "Ask AI about file" })

-- Send current line with context
vim.keymap.set("n", "<leader>cl", function()
	local pane_id, tool, err = find_ai_pane()
	if not pane_id then
		vim.notify(err, vim.log.levels.WARN)
		return
	end
	local line = vim.fn.line(".")
	local path = vim.fn.expand("%:p")
	local content = vim.api.nvim_get_current_line()
	local context = path .. ":" .. line .. "\n" .. content
	ask_ai(pane_id, tool, context)
end, { desc = "Ask AI about current line" })

-- Send diagnostics for current file
vim.keymap.set("n", "<leader>cx", function()
	local pane_id, tool, err = find_ai_pane()
	if not pane_id then
		vim.notify(err, vim.log.levels.WARN)
		return
	end
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
	ask_ai(pane_id, tool, table.concat(lines, "\n"), "Sent diagnostics to " .. tool .. " pane")
end, { desc = "Send diagnostics to AI" })
