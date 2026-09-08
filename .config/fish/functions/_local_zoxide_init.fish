function _local_zoxide_init --description 'Install one native Zoxide hook and preserve navigation shortcuts'
    status is-interactive; and command -q zoxide; or return 0
    zoxide init --cmd cd fish | source
    alias j cd
    alias ji cdi
    alias z cd
    alias zi cdi
end
