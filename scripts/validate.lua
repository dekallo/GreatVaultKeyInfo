-- Simple CI checks (Lua 5.1, luacheck job container).
-- Ensures expected addon files exist at repo root.
local required = {
  "GreatVaultKeyInfo.lua",
  "GreatVaultKeyInfo.toc",
}
for _, name in ipairs(required) do
  local f = io.open(name, "r")
  if not f then
    io.stderr:write("ci_validate: missing file: " .. name .. "\n")
    os.exit(1)
  end
  f:close()
end
print("ci_validate: ok")
os.exit(0)
