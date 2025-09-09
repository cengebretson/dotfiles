function ports --wraps='lsof -iTCP -sTCP:LISTEN -P' --description 'alias ports=lsof -iTCP -sTCP:LISTEN -P'
  lsof -iTCP -sTCP:LISTEN -P $argv; 
end
