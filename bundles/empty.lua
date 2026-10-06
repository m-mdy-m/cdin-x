-- The kernel and nothing else: what a build gets when it names `empty`, or
-- when it names `minimal`.
return {
  name = "empty",
  kind = "bundle",
  version = "1",
  description = "The cdin-x kernel with no packages and no fonts.",
  includes = {},
  fonts = false,
}