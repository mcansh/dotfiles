---
name: kero
description: Drive terminal sessions in Kero — start agents and commands in their own sessions or panes, here or on another machine, type into them, wait for them, read their screens, and report your own status. Use when running inside Kero ($KERO_PANE is set) and the task needs another terminal, a long-running process, a parallel agent, or the user's attention.
---

# Kero

You run inside Kero, a terminal whose sessions keep running in the
background. $KERO_SESSION is your session and $KERO_PANE your pane; the
`kero` command drives them. A target is a session or a pane id (a
prefix works), or a session's name; a session stands for its focused pane.

## Run something beside you

    kero split --down -- npm run dev          # a pane under yours; prints its id
    kero new -n review -- claude              # a session of its own
    kero new -n tests -d ~/code/app -- go test ./...
    kero split --url localhost:3000           # a browser pane, to show the user a page

## Drive it

    kero send <target> "some text" --enter    # type, then press Enter
    kero key <target> ctrl+c                  # enter, escape, up, tab, ctrl+d…
    kero prompt <target> "run the tests"      # send + Enter, wait, print screen
    kero wait <target> [--for idle,waiting,error,exited] [--timeout 10m]
    kero wait <target> --exit                 # until its command ends; exits with its status
    kero new --worktree <branch> -- claude    # an agent on a new branch, in a worktree of its own
    kero events [target] [--for waiting,error] [--json]
                                              # a line per change, as it happens
    kero history [query] [--json]             # agents' past conversations, to resume
    kero resume <conversation>                # a session resuming one
    kero read <target> [-n 40] [-a]           # the screen, or with scrollback
    kero status <target> --json               # status, program, directory
    kero ls                                   # every session and pane here

A pane's status is working, waiting (it needs the user), idle, error or
exited. `kero wait` with no --for waits until it stops working. A
command such as a test run doesn't show as working: wait for it with --exit,
or start it with --wait, which exits with the command's status:

    pane=$(kero split --down -- go test ./...)
    kero wait "$pane" --exit || kero read "$pane" -n 80
    kero split --down --wait -- make build    # the same, in one step

## Hand work to another machine

The user may have added other machines to Kero, each with a kerod of its
own: `kero ls --all` lists the sessions here and on every one of them,
under the name that `-H` takes, before the command:

    kero ls --all [--json]                    # every machine's sessions; a host out of reach says why
    kero hosts                                # the machines, and their addresses
    kero -H build new -n tests -d ~/code/app -- go test ./...
    kero -H build new -n review -- claude     # an agent there
    kero -H build prompt review "run the tests and fix them"
    kero -H build wait review
    kero -H build read review -n 80
    kero -H build close review

Every command acting on sessions takes -H. An id or a name is of its own
machine's sessions: give the same -H each time you act on one. With -H,
your own session is no default target, so name one each time, even for
split or notify. Paths there are that machine's, and without -d a session
starts in its project's directory, or in the home. kero focus, kero do
and kero browser drive the user's app, which a host may do only with its
Remote Control on, in Settings › Hosts: if it is off, say so rather than
work around it.

## Use a web page

A browser pane's page is yours to drive, as a user would, to check what
you built: open it with kero split --url, then

    kero browser open localhost:3000/todos     # go to a page, wait for it to load
    kero browser snapshot                      # roles, names and refs: button "Add" [ref=e5]
    kero browser click --ref e5                # click what a snapshot showed
    kero browser type --ref e3 "Buy milk"      # fill a field (--enter submits)
    kero browser click 'button[type=submit]'   # or name an element by CSS selector
    kero browser wait --text "Welcome"         # or wait <selector>; --timeout 30s
    kero browser text [selector]               # the page's text, or an element's
    kero browser html [selector]
    kero browser eval 'document.title'         # run JavaScript, print its value
    kero browser screenshot -o /tmp/page.png   # shown or not, without the focus
    kero browser back|forward|reload
    kero browser cookies save state.json       # or load: Playwright's, or cookies.txt

Refs last until the page goes to another; one whose element is gone
fails: take a new snapshot.

With no target, kero browser drives your session's browser pane; name
one (kero browser <target> text) when there are several. It needs the app
open and Remote Control on, in Settings › Agents.

## Tell the user

    kero report working "Migrating the database" --progress 40
    kero report blocked "Approve the production deploy?" --kind permission
    kero report done "Deployed to staging"
    kero notify "Need your API key to continue"

Reports are OSC 7501 sequences: Kero shows them in its sidebar, and
notifies the user when you are blocked or done while they look elsewhere.
Report blocked only when you truly cannot go on without them.

## Etiquette

- Close what you started when it is done: `kero close <target>`.
- Never type into a pane you did not start unless the user asked.
- Exit status 3 means no such target, 4 that Kero is not running.
