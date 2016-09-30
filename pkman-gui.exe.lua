-- Setup a proper search path, if possible:
local here = arg[0]:match('^(.+)[/\\]') or '.'
local dirsep = package.config:sub(1,1) or '/'
package.path  = string.format('%s%slua%s?.lua;%s%s?.lua', here, dirsep, dirsep, here, dirsep)
package.cpath = string.format('%s%slua%s?.dll', here, dirsep, dirsep)

return dofile('packagemanager-gui/main.lua')
