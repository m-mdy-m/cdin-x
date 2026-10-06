# update

Checks whether a newer cdin release exists, and badges the status bar until
the badge is dismissed.

It is a network round trip, so it runs on a coroutine and never blocks the
frame loop. Nothing happens without you asking.

**Full page:** [autoupdate — what it does, what you press, and how it works](../../../docs/plugins/autoupdate.md)
