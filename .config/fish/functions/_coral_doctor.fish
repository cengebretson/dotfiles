function _coral_doctor
    _coral_load_config

    set -f failures 0

    _coral_doctor_section "Hard dependencies"
    _coral_doctor_command fish; or set failures (math $failures + 1)
    _coral_doctor_command git; or set failures (math $failures + 1)
    _coral_doctor_command fzf; or set failures (math $failures + 1)
    if functions -q _fzf_wrapper
        _coral_doctor_ok "fzf.fish _fzf_wrapper available"
    else
        _coral_doctor_fail "fzf.fish _fzf_wrapper missing"
        set failures (math $failures + 1)
    end
    _coral_doctor_command jq; or set failures (math $failures + 1)
    _coral_doctor_command shasum; or set failures (math $failures + 1)

    if command -q fzf
        set -f fzf_ver (fzf --version 2>/dev/null | string match -r '\d+\.\d+' | head -1)
        if test -n "$fzf_ver"
            set -f major (string split . $fzf_ver)[1]
            set -f minor (string split . $fzf_ver)[2]
            if test "$major" -eq 0 -a "$minor" -lt 57
                _coral_doctor_fail "fzf $fzf_ver found; 0.57+ required"
                set failures (math $failures + 1)
            else
                _coral_doctor_ok "fzf $fzf_ver"
            end
        end
    end

    _coral_doctor_section "Optional enhancements"
    for optional in gh gum tmux curl
        if command -q $optional
            _coral_doctor_ok "$optional available"
        else
            _coral_doctor_warn "$optional unavailable; fallback behavior will be used"
        end
    end

    _coral_doctor_section "Configuration"
    set -f config_file (_coral_config_file)
    if test -f "$config_file"
        _coral_doctor_ok "config file: $config_file"
    else
        _coral_doctor_warn "config file not found: $config_file; using defaults"
    end

    if set -q CORAL_JIRA_URL_TEMPLATE
        if test -n "$CORAL_JIRA_URL_TEMPLATE"; and string match -q '*{key}*' -- "$CORAL_JIRA_URL_TEMPLATE"
            _coral_doctor_ok "CORAL_JIRA_URL_TEMPLATE configured"
        else
            _coral_doctor_warn "CORAL_JIRA_URL_TEMPLATE should include {key}"
        end
    else
        _coral_doctor_warn "CORAL_JIRA_URL_TEMPLATE unset; Jira shortcut will show a config message"
    end

    _coral_doctor_value CORAL_CACHE_TTL (_coral_cache_ttl)
    _coral_doctor_value CORAL_PR_BATCH_SIZE (_coral_pr_batch_size)
    _coral_doctor_value CORAL_PR_HISTORY_DAYS (_coral_pr_history_days)
    _coral_doctor_ok "cache dir: "(_coral_cache_dir)

    _coral_doctor_section "Repository"
    if git rev-parse --git-dir >/dev/null 2>&1
        _coral_doctor_ok "inside git repo"

        set -f current (git branch --show-current 2>/dev/null)
        if test -n "$current"
            _coral_doctor_ok "current branch: $current"
        else
            _coral_doctor_warn "detached HEAD; branch checkout/rebase actions are limited"
        end

        set -f origin (git remote get-url origin 2>/dev/null)
        if test -n "$origin"
            _coral_doctor_ok "origin: $origin"
        else
            _coral_doctor_warn "no origin remote; PR cache and GitHub enrichment unavailable"
        end

        set -f cache_file (_coral_cache_file)
        if test -n "$cache_file"
            _coral_doctor_ok "cache file: $cache_file"
        else
            _coral_doctor_warn "cache file unavailable"
        end

        set -f base (_coral_base_branch 2>/dev/null)
        if test -n "$base"
            _coral_doctor_ok "base branch: $base"
        else
            _coral_doctor_warn "base branch could not be inferred"
        end

        if command -q gh
            gh auth status >/dev/null 2>&1
            and _coral_doctor_ok "gh auth ok"
            or _coral_doctor_warn "gh auth status failed; PR enrichment may be unavailable"
        end
    else
        _coral_doctor_warn "not inside a git repo; repo-specific checks skipped"
    end

    test $failures -eq 0
end
