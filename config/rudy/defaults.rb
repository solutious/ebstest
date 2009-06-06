defaults do                          # Global Defaults
  region :"us-east-1" 
  zone :"us-east-1b" 
  environment :linux
  role :small
  user Rudy.sysinfo.user.to_sym
  color true                         # set to true for terminal colors
  yes false
end