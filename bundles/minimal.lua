-- The kernel, and nothing else: what a build gets when it names no packages.
return {
  name = "minimal",
  kind = "bundle",
  version = "1",
  description = "The cdin-x kernel with no packages.",
  includes = {},
}