source (dirname (status --current-filename))/helpers.fish

set temp_cache_home (mktemp -d)
set -gx XDG_CACHE_HOME $temp_cache_home

set temp_repo (mktemp -d)
git -C "$temp_repo" init -q
git -C "$temp_repo" remote add origin git@github.com:example/repo.git

coral_test_reset
cd "$temp_repo"
set cache_file (_coral_cache_file)

@test "cache file is under XDG cache dir" (string match -q "$temp_cache_home/coral/pr/*.cache" "$cache_file"; echo $status) = 0
@test "cache dir is created" -d "$temp_cache_home/coral/pr"

rm -rf "$temp_repo" "$temp_cache_home"
