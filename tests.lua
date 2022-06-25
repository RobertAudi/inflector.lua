local inflector = require("inflector")
local counters = { assertions = 0, passed = 0, failed = 0 }

local function loadcode(code, environment)
  if setfenv and loadstring then
    local f = assert(loadstring(code))
    setfenv(f, environment)
    return f
  else
    return assert(load(code, nil, "t", environment))
  end
end

local function inspect(o)
  if type(o) == "table" then
    local s = "{ "

    for k, v in pairs(o) do
      if type(k) ~= "number" then
        k = "\"" .. k .. "\""
      end

      s = s .. "[" .. k .. "] = " .. inspect(v) .. ","
    end

    return s .. "} "
  elseif type(o) == "string" then
    return "\"" .. o:gsub("\"", "\\\"") .. "\""
  else
    return tostring(o)
  end
end

local function hr(title, sep, len)
  sep = tostring(sep or "-")
  len = len or 72
  local ruler = sep:rep(len)

  if title ~= nil then
    ruler = tostring(title) .. "\n" .. ruler
  else
    ruler = ruler
  end

  print(ruler)
end

local function pass(message)
  counters.assertions = counters.assertions + 1
  counters.passed = counters.passed + 1

  print("[\27[32mPASS\27[0m] " .. tostring(message))
end

local function fail(message, err)
  counters.assertions = counters.assertions + 1
  counters.failed = counters.failed + 1

  message = "[\27[31mFAIL\27[0m] " .. tostring(message)

  if err ~= nil then
    message = message .. " -- [\27[31mERROR\27[0m] " .. tostring(err)
  end

  print(message)
end

local function assert_error(expectation)
  local ok, _ = pcall(function()
    loadcode(expectation, { inflector = inflector })()
  end)

  local message = "throws error: " .. tostring(expectation)

  if ok then
    fail(message)
  else
    pass(message)
  end
end

local function assert_plural(value, expectation)
  local message = "inflector.pluralize(" .. inspect(value) .. ") == " .. inspect(expectation)

  local ok, plural = pcall(function()
    return inflector.pluralize(value)
  end)

  if not ok then
    fail(message, plural)
  elseif plural == expectation then
    pass(message)
  else
    fail(message)
  end
end

local function assert_singular(value, expectation)
  local message = "inflector.singularize(" .. inspect(value) .. ") == " .. inspect(expectation)

  local ok, singular = pcall(function()
    return inflector.singularize(value)
  end)

  if not ok then
    fail(message, singular)
  elseif singular == expectation then
    pass(message)
  else
    fail(message)
  end
end

-- ------------------------------------------------------------------------ --
-- Tests                                                                    --
-- ------------------------------------------------------------------------ --

hr(nil, "~")
hr("Lua version: " .. (type(jit) == "table" and jit.version or _VERSION), "~")
print()

hr("singularize / pluralize", "+")
print()

assert_error([[inflector.pluralize(nil)]])
assert_error([[inflector.singularize(nil)]])

assert_plural("", "")
assert_singular("", "")

assert_plural("user", "users")
assert_plural("users", "users")
assert_singular("users", "user")
assert_singular("user", "user")

assert_plural("axis", "axes")
assert_plural("Axis", "Axes")

assert_plural("octopus", "octopi")

assert_plural("psychoanalyses", "psychoanalyses")
assert_plural("psychoanalysis", "psychoanalyses")

print()
hr("Irregular words")

for _, rule in pairs(inflector.rules.irregular) do
  assert_plural(rule.plural, rule.plural)
  assert_plural(rule.singular, rule.plural)
  assert_singular(rule.plural, rule.singular)
  assert_singular(rule.singular, rule.singular)
end

hr()
print()

hr("Uncountable words")

for _, word in pairs(inflector.rules.uncountable) do
  assert_plural(word, word)
  assert_singular(word, word)
end

-- ------------------------------------------------------------------------ --

print("\n")
hr(nil, "=")

print(
  "\n\n    Assertions: \27[33m"
    .. tostring(counters.assertions)
    .. "\27[0m Passed: \27[32m"
    .. tostring(counters.passed)
    .. "\27[0m Failed: \27[31m"
    .. tostring(counters.failed)
    .. "\27[0m\n\n"
)

print("Done.")
