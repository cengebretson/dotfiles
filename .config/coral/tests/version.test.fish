source (dirname (status --current-filename))/helpers.fish

@test "_coral_version prints current version" (_coral_version) = "0.1.0"
@test "coral --version prints current version" (coral --version) = "0.1.0"
