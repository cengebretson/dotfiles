function fish_greeting
    select_random_image
    fastfetch
end

function select_random_image

  # Get all files in the directory
  set files (ls ~/.config/fastfetch/option*)

  # Pick a random file
  set count (count $files)
  set rand (random 1 $count)
  set selected $files[$rand]

  cp $selected ~/.config/fastfetch/ascii.txt
end
