set fish_config_dir (path resolve (dirname (status --current-filename))/..)

source "$fish_config_dir/functions/ports.fish"
source "$fish_config_dir/functions/keychain.fish"

@test "_ports_valid_port accepts the lower bound" (_ports_valid_port 1; echo $status) = 0
@test "_ports_valid_port accepts the upper bound" (_ports_valid_port 65535; echo $status) = 0
@test "_ports_valid_port rejects zero" (_ports_valid_port 0; echo $status) = 1
@test "_ports_valid_port rejects values above 65535" (_ports_valid_port 65536; echo $status) = 1
@test "_ports_valid_port rejects non-numeric input" (_ports_valid_port ssh; echo $status) = 1

@test "_keychain_valid_env_name accepts a shell name" (_keychain_valid_env_name GH_TOKEN; echo $status) = 0
@test "_keychain_valid_env_name accepts a leading underscore" (_keychain_valid_env_name _TOKEN_2; echo $status) = 0
@test "_keychain_valid_env_name rejects an option-like name" (_keychain_valid_env_name --erase; echo $status) = 1
@test "_keychain_valid_env_name rejects punctuation" (_keychain_valid_env_name BAD-NAME; echo $status) = 1
