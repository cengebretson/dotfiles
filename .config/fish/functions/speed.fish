function speed --description 'alias speed=networkQuality'
  if count $argv > /dev/null #Checks for option
  command networkQuality $argv
  else
  command networkQuality
  end
end

