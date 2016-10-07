-- Setup a proper search path, if possible:
local here = arg[0]:match('^(.+)[/\\]') or '.'
local dirsep = package.config:sub(1,1) or '/'
package.path  = string.format('%s%s?.lua', here, dirsep)
package.cpath = string.format('%s%s?.dll', here, dirsep)

return dofile(here..dirsep..'packagemanager-cli/main.lua')
