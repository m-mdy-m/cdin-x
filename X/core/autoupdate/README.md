# autoupdate

Checks whether a newer cdin release is available and badges the status bar
until the badge is dismissed.

The release check is a network round trip, so it runs on a coroutine and
never blocks the frame loop.