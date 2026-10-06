-- What a cdin build has always carried: vim mode and the themes.
--
-- The extension manager is not named here, because it is not a package. Every
-- bundle writes the kernel and its shim into the build, and the shim is what the
-- host loads: the panel is reachable because the kernel is there, not because a
-- bundle listed something. Naming it would make the one thing a build cannot do
-- without look like a thing a build can leave out.
--
-- `themes`, not `default`: the ten themes are files *inside* the themes package
-- rather than ten catalog entries of their own, so a bundle names the package and
-- the bundler puts each theme where the host looks for it.
return {
  name = "standard",
  kind = "bundle",
  version = "1",
  description = "Vim mode and the bundled themes.",
  includes = { "vim", "themes" },
}