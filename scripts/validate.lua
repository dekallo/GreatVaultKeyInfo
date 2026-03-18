-- Validate addon structure. Exits 0 on success, 1 on failure.
-- Use --fail to force failure (for testing error reporting).
local args = {...}
if #args > 0 and args[1] == "--fail" then
  io.stderr:write("Validation failed (--fail)\n")
  os.exit(1)
end

local required = {
  "GreatVaultKeyInfo.toc",
  "GreatVaultKeyInfo.lua",
  "Locales/enUS.lua",
}

local path = args[1] or "."
if path:sub(-1) ~= "/" then
  path = path .. "/"
end

local missing = {}
for _, file in ipairs(required) do
  local f = io.open(path .. file, "r")
  if not f then
    table.insert(missing, file)
  else
    f:close()
  end
end

if #missing > 0 then
  io.stderr:write("Missing required files: " .. table.concat(missing, ", ") .. "\n")
  os.exit(1)
end

print("Validation passed")
os.exit(0)
