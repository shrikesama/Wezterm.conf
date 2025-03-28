local platform = require('utils.platform')

local options = {
   default_prog = {},
   launch_menu = {},
}

-- TODO
if platform.is_win then
   options.default_prog = { 'powershell' }
   options.launch_menu = {
      { label = 'PowerShell Core',    args = { 'pwsh', '-NoLogo' } },
      { label = 'PowerShell Desktop', args = { 'powershell' } },
      { label = 'Command Prompt',     args = { 'cmd' } },
      { label = 'Nushell',            args = { 'nu' } },
      { label = 'Msys2',              args = { 'ucrt64.cmd' } },
      {
         label = 'Git Bash',
         args = { 'C:\\Users\\kevin\\scoop\\apps\\git\\current\\bin\\bash.exe' },
      },
   }
elseif platform.is_mac then
   --options.default_prog = { '/opt/homebrew/bin/fish', '-l' }
   options.default_prog = { 'zsh', '-l' }
   options.launch_menu = {
      { label = 'Bash',    args = { 'bash', '-l' } },
      { label = 'Fish',    args = { 'fish', '-l' } },
      { label = 'Nushell', args = { 'nu', '-l' } },
      { label = 'Zsh',     args = { 'zsh', '-l' } },
   }
elseif platform.is_linux then
   options.default_prog = { 'fish', '-l' }
   options.launch_menu = {
      { label = 'Bash', args = { 'bash', '-l' } },
      { label = 'Fish', args = { 'fish', '-l' } },
      { label = 'Zsh',  args = { 'zsh', '-l' } },
   }
end

return options
