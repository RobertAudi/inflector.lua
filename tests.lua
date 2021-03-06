local inflector = require("inflector")
local counters = { assertions = 0, passed = 0, failed = 0 }

-- Source: https://stackoverflow.com/a/9279009/123016
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

-- ------------------------------------------------------------------------ --

local function test(tests_or_title, tests)
  if type(tests_or_title) == "string" then
    hr(tests_or_title, "+")
    print()

    pcall(tests)
  elseif type(tests_or_title) == "function" then
    pcall(tests_or_title)
  else
    pcall(tests)
  end

  print()
end

local function pass(message)
  counters.assertions = counters.assertions + 1
  counters.passed = counters.passed + 1

  print("[\27[32mPASS\27[0m] " .. tostring(message))
end

local function fail(message, opts)
  opts = opts or {}

  counters.assertions = counters.assertions + 1
  counters.failed = counters.failed + 1

  message = "[\27[31mFAIL\27[0m] " .. tostring(message)

  if opts.result ~= nil then
    message = message .. " (Result: " .. inspect(opts.result) .. ")"
  end

  if opts.error ~= nil then
    message = message .. " -- [\27[31mERROR\27[0m] " .. tostring(opts.error)
  end

  print(message)
end

-- ------------------------------------------------------------------------ --
-- Assertions                                                               --
-- ------------------------------------------------------------------------ --

local function assert_expression_eq(expression, expectation)
  if not type(expression) == "string" then
    error("expected the first argument of assert_eq must be a string but received a " .. type(expression))
  end

  local message = expression .. " == " .. inspect(expectation)

  local ok, value = pcall(function()
    if not expression:match("^return ") then
      expression = "return " .. expression
    end

    return loadcode(expression, { inflector = inflector })()
  end)

  if not ok then
    fail(message, { error = value })
  elseif value == expectation then
    pass(message)
  else
    fail(message, { result = value })
  end
end

local function assert_inflection(inflection, actual, expected)
  local message = "inflector." .. inflection .. "(" .. inspect(actual) .. ") == " .. inspect(expected)
  local ok, value = pcall(inflector[inflection], actual)

  if not ok then
    fail(message, { error = value })
  elseif value == expected then
    pass(message)
  else
    fail(message, { result = value })
  end
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
    fail(message, { error = plural })
  elseif plural == expectation then
    pass(message)
  else
    fail(message, { result = plural })
  end
end

local function assert_singular(value, expectation)
  local message = "inflector.singularize(" .. inspect(value) .. ") == " .. inspect(expectation)

  local ok, singular = pcall(function()
    return inflector.singularize(value)
  end)

  if not ok then
    fail(message, { error = singular })
  elseif singular == expectation then
    pass(message)
  else
    fail(message, { result = singular })
  end
end

-- ------------------------------------------------------------------------ --

-- ------------------------------------------------------------------------ --
-- Tests                                                                    --
-- ------------------------------------------------------------------------ --

hr(nil, "~")
hr("Lua version: " .. (type(jit) == "table" and jit.version or _VERSION), "~")
print()

test("singularize / pluralize", function()
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

  assert_plural("alias", "aliases")
  assert_plural("aliases", "aliases")
  assert_plural("status", "statuses")
  assert_plural("statuses", "statuses")

  assert_singular("aliases", "alias")
  assert_singular("alias", "alias")
  assert_singular("statuses", "status")
  assert_singular("status", "status")

  assert_plural("bus", "busses")
  assert_plural("busses", "busses")
  assert_singular("buses", "bus")
  assert_singular("busses", "bus")
  assert_singular("bus", "bus")

  assert_plural("omnibus", "omnibusses")
  assert_plural("omnibusses", "omnibusses")
  assert_singular("omnibuses", "omnibus")
  assert_singular("omnibusses", "omnibus")
  assert_singular("omnibus", "omnibus")

  assert_plural("tomato", "tomatoes")
  assert_plural("tomatoes", "tomatoes")
  assert_plural("buffalo", "buffaloes")
  assert_plural("buffaloes", "buffaloes")
  assert_singular("tomato", "tomato")
  assert_singular("tomatoes", "tomato")
  assert_singular("buffalo", "buffalo")
  assert_singular("buffaloes", "buffalo")

  assert_plural("consortium", "consortia")
  assert_plural("consortia", "consortia")
  assert_singular("consortia", "consortium")
  assert_singular("consortium", "consortium")

  assert_plural("analyses", "analyses")
  assert_plural("analysis", "analyses")
  assert_plural("psychoanalyses", "psychoanalyses")
  assert_plural("psychoanalysis", "psychoanalyses")

  assert_plural("wife", "wives")
  assert_plural("wives", "wives")
  assert_singular("wives", "wife")
  assert_singular("wife", "wife")

  assert_plural("elf", "elves")
  assert_plural("elves", "elves")
  assert_singular("elves", "elf")
  assert_singular("elf", "elf")

  assert_plural("hive", "hives")
  assert_plural("hives", "hives")
  assert_singular("hives", "hive")
  assert_singular("hive", "hive")

  assert_plural("beehive", "beehives")
  assert_plural("beehives", "beehives")
  assert_singular("beehives", "beehive")
  assert_singular("beehive", "beehive")

  assert_plural("tally", "tallies")
  assert_plural("tallies", "tallies")
  assert_singular("tallies", "tally")
  assert_singular("tally", "tally")

  assert_plural("colloquy", "colloquies")
  assert_plural("colloquies", "colloquies")
  assert_singular("colloquies", "colloquy")
  assert_singular("colloquy", "colloquy")

  assert_plural("complex", "complexes")
  assert_plural("complexes", "complexes")
  assert_singular("complexes", "complex")
  assert_singular("complex", "complex")

  assert_plural("porch", "porches")
  assert_plural("porches", "porches")
  assert_singular("porches", "porch")
  assert_singular("porch", "porch")

  assert_plural("process", "processes")
  assert_plural("processes", "processes")
  assert_singular("processes", "process")
  assert_singular("process", "process")

  assert_plural("dish", "dishes")
  assert_plural("dishes", "dishes")
  assert_singular("dishes", "dish")
  assert_singular("dish", "dish")

  assert_plural("fish", "fish")
  assert_singular("fish", "fish")
  assert_plural("blowfish", "blowfish")
  assert_singular("blowfish", "blowfish")

  assert_plural("deer", "deer")
  assert_singular("deer", "deer")
  assert_plural("raindeer", "raindeer")
  assert_singular("raindeer", "raindeer")

  assert_plural("matrix", "matrices")
  assert_plural("matrices", "matrices")
  assert_singular("matrices", "matrix")
  assert_singular("matrix", "matrix")

  assert_plural("index", "indices")
  assert_plural("indices", "indices")
  assert_singular("indices", "index")
  assert_singular("index", "index")

  assert_plural("vertex", "vertices")
  assert_plural("vertices", "vertices")
  assert_singular("vertices", "vertex")
  assert_singular("vertex", "vertex")

  assert_plural("mouse", "mice")
  assert_plural("mice", "mice")
  assert_singular("mice", "mouse")
  assert_singular("mouse", "mouse")

  assert_plural("man", "men")
  assert_plural("men", "men")
  assert_plural("woman", "women")
  assert_plural("women", "women")
  assert_singular("men", "man")
  assert_singular("man", "man")
  assert_singular("women", "woman")
  assert_singular("woman", "woman")

  assert_plural("ox", "oxen")
  assert_plural("oxen", "oxen")
  assert_singular("oxen", "ox")
  assert_singular("ox", "ox")

  assert_plural("quiz", "quizzes")
  assert_plural("quizzes", "quizzes")
  assert_singular("quizzes", "quiz")
  assert_singular("quiz", "quiz")

  assert_plural("pubquiz", "pubquizzes")
  assert_plural("pubquizzes", "pubquizzes")
  assert_singular("pubquizzes", "pubquiz")
  assert_singular("pubquiz", "pubquiz")

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
end)

test("upcase_first", function()
  assert_inflection("upcase_first", "foo_bar", "Foo_bar")
  assert_inflection("upcase_first", "foo_Bar", "Foo_Bar")
  assert_inflection("upcase_first", "Foo_Bar", "Foo_Bar")
  assert_inflection("upcase_first", "fooBar", "FooBar")
  assert_inflection("upcase_first", "FooBar", "FooBar")
end)

test("downcase_first", function()
  assert_inflection("downcase_first", "foo_bar", "foo_bar")
  assert_inflection("downcase_first", "foo_Bar", "foo_Bar")
  assert_inflection("downcase_first", "Foo_Bar", "foo_Bar")
  assert_inflection("downcase_first", "fooBar", "fooBar")
  assert_inflection("downcase_first", "FooBar", "fooBar")
end)

test("camel_case", function()
  local words = {
    fooBar = {
      "foo_bar",
      "foo_Bar",
      "Foo_Bar",

      "foo-bar",
      "foo-Bar",
      "Foo-Bar",

      "fooBar",
      "FooBar",
    },

    fooBarBaz = {
      "foo_bar_baz",
      "foo_Bar_baz",
      "Foo_Bar_baz",

      "foo-bar_baz",
      "foo-Bar_baz",
      "Foo-Bar_baz",

      "foo_bar-baz",
      "foo_Bar-baz",
      "Foo_Bar-baz",

      "foo-bar-baz",
      "foo-Bar-baz",
      "Foo-Bar-baz",

      "fooBar-baz",
      "FooBar-baz",

      "fooBar_baz",
      "FooBar_baz",
    },
  }

  for expected, values in pairs(words) do
    for _, actual in pairs(values) do
      assert_inflection("camel_case", actual, expected)
      assert_inflection("camelCase", actual, inflector.camel_case(actual))
      assert_inflection("camelize", actual, inflector.camel_case(actual))
      assert_inflection("camel", actual, inflector.camel_case(actual))
    end
  end
end)

test("pascal_case", function()
  local words = {
    FooBar = {
      "foo_bar",
      "foo_Bar",
      "Foo_Bar",

      "foo-bar",
      "foo-Bar",
      "Foo-Bar",

      "fooBar",
      "FooBar",
    },

    FooBarBaz = {
      "foo_bar_baz",
      "foo_Bar_baz",
      "Foo_Bar_baz",

      "foo-bar_baz",
      "foo-Bar_baz",
      "Foo-Bar_baz",

      "foo_bar-baz",
      "foo_Bar-baz",
      "Foo_Bar-baz",

      "foo-bar-baz",
      "foo-Bar-baz",
      "Foo-Bar-baz",

      "fooBar_baz",
      "FooBar_baz",

      "fooBar-baz",
      "FooBar-baz",
    },
  }

  for expected, values in pairs(words) do
    for _, actual in pairs(values) do
      assert_inflection("pascal_case", actual, expected)
      assert_inflection("pascal", actual, inflector.pascal_case(actual))
    end
  end
end)

test("snake_case", function()
  local words = {
    foo_bar = {
      "foo_bar",
      "foo_Bar",
      "Foo_Bar",

      "foo-bar",
      "foo-Bar",
      "Foo-Bar",

      "fooBar",
      "FooBar",
    },
    foo_bar_baz = {
      "foo_bar_baz",
      "foo_Bar_baz",
      "Foo_Bar_baz",

      "foo-bar-baz",
      "foo-Bar-baz",
      "Foo-Bar-baz",

      "foo-bar_baz",
      "foo-Bar_baz",
      "Foo-Bar_baz",

      "foo_bar-baz",
      "foo_Bar-baz",
      "Foo_Bar-baz",

      "fooBar_baz",
      "FooBar_baz",

      "fooBar-baz",
      "FooBar-baz",

      "fooBarBaz",
      "FooBarBaz",
    },
  }

  for expected, values in pairs(words) do
    for _, actual in pairs(values) do
      assert_inflection("snake_case", actual, expected)
      assert_inflection("snake", actual, inflector.snake_case(actual))
      assert_inflection("underscore", actual, inflector.snake_case(actual))
    end
  end
end)

test("dasherize", function()
  assert_inflection("dasherize", "foo_bar", "foo-bar")
  assert_inflection("dasherize", "foo_Bar", "foo-Bar")
  assert_inflection("dasherize", "Foo_Bar", "Foo-Bar")
  assert_inflection("dasherize", "fooBar", "fooBar")
  assert_inflection("dasherize", "FooBar", "FooBar")

  assert_inflection("dasherize", "foo_bar_baz", "foo-bar-baz")
  assert_inflection("dasherize", "foo_Bar_baz", "foo-Bar-baz")
  assert_inflection("dasherize", "Foo_Bar_baz", "Foo-Bar-baz")
  assert_inflection("dasherize", "fooBar_baz", "fooBar-baz")
  assert_inflection("dasherize", "FooBar_baz", "FooBar-baz")
  assert_inflection("dasherize", "fooBarBaz", "fooBarBaz")
  assert_inflection("dasherize", "FooBarBaz", "FooBarBaz")
end)

-- ------------------------------------------------------------------------ --

print()
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

if counters.failed > 0 then
  os.exit(1)
else
  os.exit(0)
end
