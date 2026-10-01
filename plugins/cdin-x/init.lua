-- The site-install entry point, and nothing else.
--
-- An installed cdin-x and a bundled cdin-x are the same manager; what
-- differs is only how the host finds it. This file is what a build of the
-- *editor* finds when cdin-x was installed into the site directory, and it
-- hands straight over to the same module the bundle ships. Two copies of a
-- bootstrap would be two things to keep in step, and the day they disagree
-- the panel will be the thing that is wrong.
return require("X.core.manager")
