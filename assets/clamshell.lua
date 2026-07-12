-- Clamshell: lid closed + AC connected -> DPMS internal panel off.
-- Probes hardware at load; machines without a lid (desktop) get no-op stubs.
local M = {}

local INTERNAL = "eDP-1"

local function read(path)
  if path == nil then
    return nil
  end
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local s = f:read("*a")
  f:close()
  return s
end

local function glob_first(pattern)
  local p = io.popen("ls -d " .. pattern .. " 2>/dev/null")
  if not p then
    return nil
  end
  local line = p:read("*l")
  p:close()
  return line
end

local lid_path = glob_first("/proc/acpi/button/lid/*/state")

-- all Mains-type supplies (ADP1 here; AC/ACAD elsewhere). None found -> never blank.
local ac_paths = {}
do
  local p = io.popen("ls -d /sys/class/power_supply/*/type 2>/dev/null")
  if p then
    for line in p:lines() do
      local t = read(line)
      if t and t:find("Mains") then
        table.insert(ac_paths, (line:gsub("/type$", "/online")))
      end
    end
    p:close()
  end
end

local function lid_closed()
  local s = read(lid_path)
  return s ~= nil and s:find("closed") ~= nil
end

local function on_ac()
  for _, path in ipairs(ac_paths) do
    local s = read(path)
    if s and s:match("^%s*1") then
      return true
    end
  end
  return false
end

local last

local function apply(desired)
  if desired == last then
    return
  end
  last = desired
  -- dpms must not be dispatched directly from bind context; defer via oneshot timer
  hl.timer(function()
    hl.dispatch(hl.dsp.dpms({ action = desired, monitor = INTERNAL }))
  end, { timeout = 500, type = "oneshot" })
end

if lid_path == nil then
  function M.reconcile() end
  function M.wake()
    hl.dispatch(hl.dsp.dpms({ action = "on" }))
  end
else
  function M.reconcile()
    apply((lid_closed() and on_ac()) and "off" or "on")
  end

  -- resume / idle-wake: light every monitor except the internal one,
  -- then let policy decide the internal panel (avoids closed-lid flash)
  function M.wake()
    for _, m in ipairs(hl.get_monitors()) do
      if m.name ~= INTERNAL then
        hl.dispatch(hl.dsp.dpms({ action = "on", monitor = m.name }))
      end
    end
    last = nil
    M.reconcile()
  end

  hl.bind("switch:on:Lid Switch", M.reconcile, { locked = true })
  hl.bind("switch:off:Lid Switch", M.reconcile, { locked = true })
end

-- entry points for hypridle via hyprctl eval
clamshell_reconcile = M.reconcile
clamshell_wake = M.wake

return M
