# Changelog

## Unreleased

### Tiling

- New `master` layout, after Hyprland's: one window, the master, takes 0.6 of the display (`[master] size`) on the left or right (`[master] side`) and the others stack beside it. The first window fills the display alone, the second opens the stack and later ones join its bottom. When the master closes, the top of the stack takes its place; when the stack empties, the master fills the display again. `layout tiles accordion` toggles the stack between tiles and an accordion from any window.
- `layout master` switches the focused workspace to the master layout, making the focused window the master and stacking the others as they were shown, tiled or in an accordion. `layout dwindle` switches a master or scrolling workspace back to its tree. Both are in the Layout menu.
- New `swap-with-master` command, Hyprland's `swapwithmaster`: swaps the focused window with the master, or the master with the top of the stack.

### Fixes

- A browser's picture-in-picture window no longer takes dinky's focus (#13). Chromium browsers keep it above every other window and tag it like a document window, so once it was open, dinky took it for the focused one, and `focus` answered "no focused window" until it was closed. Windows above the normal level are now passed over: focus stays with the tiled window beneath, and `focus left` and friends work with the video playing.
- A CLI argument with both `'` and `"` in it, such as a `--format` of `it's "%{app-name}"`, or one starting with a combining accent, reaches dinky as typed. Before, quotes were lost, and some mixes swallowed the flags after it.
- `exec-and-forget` finds Homebrew's commands on Intel Macs, where Homebrew lives in `/usr/local`. Before, hooks like the `sketchybar` examples failed there when dinky was started from Finder or at login.
- `dinky doctor` says dinky is developed and tested on macOS 27. Before, it claimed every build was built against 27.0, whichever SDK built it.
- When dinky can't listen to the keyboard, as can happen right after Accessibility is granted, it keeps trying and the menu bar shows `!` with a menu line saying the key bindings are off. Before, the bindings stayed dead until dinky restarted, with nothing to say so.
- Resizing with the keyboard leaves a window alone when it shares its container with ten or more others, as after `flatten-workspace-tree` with eleven windows. Before, growing it made it vanish.
- `join-with left` and `right` in the scrolling layout put a window into the neighbouring column even when it sits side by side with another inside its column. Before, it joined that other window instead.
- Showing, hiding or moving the Dock, or turning menu bar hiding on or off, fits the tiles to the new free area. Before, they kept the old one until something else changed, overlapping the Dock or leaving a gap.
- Switching workspaces on two displays in quick succession lands each display where it was sent. Before, a switch asked for while the other display's switch moved the pointer could be dropped, with its follow-up running on the old Space.
- A `dinky.toml` that is a symlink to a missing file, such as one into a dotfiles checkout not cloned yet, stays a symlink. Before, dinky replaced it with the default config at launch.
- A `dinky.toml` that is a symlink reloads when the link itself is replaced, as `ln -sf` or a dotfiles tool does it. Before, dinky went on watching the file the old link pointed to.
- dinky stops watching the config for good when it stops. Before, a watch stopped while `dinky.toml` was missing came back once the file appeared, and reported a reload.
- Switching to an empty workspace stays there with app activation following on. Before, on a Mac where the switch took longer than 300 ms to land, such as an Intel Mac before macOS 27, Finder's activation on arrival was taken for one you asked for, and dinky followed it straight back to the workspace you left.
- On macOS before 27, apps that stop drawing while hidden, like Ghostty, show their content after a workspace switch. Before, the switch skipped macOS's animation, so their windows were never told they were visible again and showed only their border until Cmd-Tab or Show Desktop. A switch across several workspaces plays the animation once, for the last step.
- A frontmost app that stops responding no longer stalls typing everywhere. Before, dinky asked it for its focused window twice a second with no time limit, on the thread that also handles key bindings.
- Reading whether a new window's fullscreen button is enabled gives up after a second, like every other question dinky asks an app. Before, an app that stopped responding could hold dinky up for 6 seconds there.
- An app that stops responding no longer holds up the next arrangement, or disabling and quitting dinky. Before, raising its windows into their stacking order blocked for seconds, and everything waiting on that arrangement waited too.
- Overlapping windows, as in an accordion, end up in the stacking order of the latest arrangement when an app is slow to answer. Before, an earlier arrangement that waited on that app could raise its windows last, putting the old order back.
- Disabled dinky leaves windows and Spaces alone. Before, while off it still ran `[[rules]]` on new windows, moved new windows to the focused display, and rearranged workspaces on a config reload or display change. A `dinky enable off` sent before Accessibility was granted no longer gets lost either.
- dinky started disabled, as after a `dinky enable off` sent before Accessibility was granted, leaves windows where they are when it quits. Before, it put them back where they were when Accessibility was granted, undoing whatever you had moved since.
- Disabling, quitting and `dinky recover` put windows back where they were when dinky launched. Before, the frames recorded as the originals could already be the tiled ones, so restoring left windows tiled.
- A window that could not be put back, because its display was unplugged or its app did not answer, stays journaled, so the next disable, quit or `dinky recover` tries it again, unless you move it by hand in the meantime: then it stays where you put it. Before, it was forgotten after the first try.
- One app that stops responding while windows are being put back no longer spoils the report for the others. Before, every window counted as not restored when any app took longer than 3 seconds.
- Windows moved since a display was plugged in or out stay where you put them. Before, when arranging the workspaces right after the display change stopped short, a later config reload sent windows back to where they had been before that change.
- Turning dinky back on leaves windows where you put them after a display was plugged in or out while it was off. Before, enabling it, hours later perhaps, sent them back to where they were before the display change.

## 0.19

### Tiling

- New `[workspace.<number>.display.<pattern>]` tables give a workspace other settings while it is on one display, such as two fixed columns on an ultrawide and an accordion on the laptop screen. When you dock or undock, the workspace switches layout as it moves.
- Switching workspaces is lighter and no longer sets windows gliding. A switch reads only the workspace you arrive at and lays it out only if something changed there while you were away, so its windows are in place as it shows.
- Dragging a window is lighter, so the drag stays smooth and its border keeps up.

### Key bindings

- `hyper` and `meh` name the usual modifier combinations: `hyper-1` is `alt-ctrl-cmd-shift-1`, and `meh-1` is `alt-ctrl-shift-1`.

### Rules

- New `app-id-regex` key matches the bundle ID by regex, like `app-name` does for the app's name: `app-id-regex = '^com\.jetbrains\.'` covers every JetBrains app with one rule. `app-id` still matches exactly.

### Hooks

- New `display-changed` hook runs when a display connects or disconnects, once the workspaces have moved, with `DINKY_DISPLAYS` and `DINKY_PREV_DISPLAYS` set to how many displays there are now and were before. React to docking and undocking without Hammerspoon.
- `exec-and-forget` has `dinky` itself on `PATH`, so hook scripts can call `dinky` when the app was started from Finder.

### Fixes

- Turning dinky off takes its borders away and leaves window drags alone: no drop outlines, and no swap or resize remembered for when it comes back on.
- dinky keeps tiling a window after its app closes and reopens it, as Slack does when you close its window with Cmd-W and open it again from the Dock.
- Terminal windows shrink again. Terminal sizes its windows in whole rows and columns, so it never lands exactly on its tile; a size now counts as a minimum only when the window comes back at it for two different sizes asked, so that miss no longer passes for one. Minimum sizes saved by earlier versions are forgotten once.
- `move`, `join-with` and `resize` succeed when there is nothing to do, such as `move left` on a window already at the left edge: the CLI prints `move left: nothing to do` and exits 0, so launchers like LeaderKey show no error.
- A `layout` command keeps a `fixed` workspace's template when it leaves its shape alone, such as one that changes nothing or turns the overflow accordion vertical, so later windows still fill the grid.
- Releases say they need Apple silicon, so a dinky built from source on an Intel Mac doesn't offer to update itself to one, and `brew install` stops with a clear message.

## 0.18

### Key bindings

- New `[modifiers]` table picks which key of each modifier pair your bindings answer to: `'both'` (the default), `'left'` or `'right'`. With `alt = 'left'`, left Option runs dinky's bindings and right Option types special characters like `˙` and `≈` as usual.

## 0.17

### Menu

- Layout > Scrolling switches the focused window's workspace to the scrolling layout.

### Fixes

- Switching more than one workspace away no longer stops on the workspaces in between. Before, macOS briefly activated the app on each one it passed, which put that app into the Cmd-Tab order. Multi-step switches are faster too.
- Borders stay on while focus moves during an animation, such as scrolling the scrolling layout. Before, the borders of the window losing focus and the one gaining it blinked off until the windows arrived.
- Switching workspaces works with natural scrolling off. Before, on macOS 27 the swipe went the wrong way and bounced back to the workspace you were on, and following an app from the Dock or Cmd-Tab failed the same way.
- Switching workspaces on macOS before 27 uses the swipe those versions understand. Before, it bounced back there too.

## 0.16

### Tiling

- New `scrolling` layout, after niri and Hyprland: windows open as columns in a row that scrolls past the display edges to the focused one. Columns are 0.49 of the display wide by default, as Omarchy sets them (`[scrolling] column-width`); a lone column fills the display. Columns out of view hang off the edge with a sliver showing, an inner gap from the columns in view, or wait behind the columns in view where another display is beyond.
- `layout scrolling` switches the focused workspace to scrolling and `layout tiles` or `accordion` back, and `layout` with several names now cycles through them: `layout tiles accordion scrolling`.

## 0.15

### Tiling

- New windows open on the focused display, unless a rule moves them.

### Fixes

- An empty workspace activates Finder, even with the desktop turned off, so typing no longer goes to an app on another workspace.

## 0.14

### Install

- The Homebrew cask installs on macOS 15 or later, as the app supports. Before, it asked for a newer macOS.

### Command line

- `dinky -v` prints the version, like `dinky version` and `dinky --version`.

### Fixes

- Switching to an empty workspace keeps focus on its display. Before, macOS could hand focus to a window on another display, so typing and the next `workspace next` went there. `focus-monitor` onto an empty display also takes the keyboard off the other display's window.

## 0.13

### Tiling

- Windows that can't go full screen float on their own, like Finder's copy progress window, About This Mac and Calculator. Terminals and editors that can hide their title bar still tile. Set `float-windows-without-fullscreen = false` to tile them as before, or tile a single app with a `layout tiling` rule.

## 0.12

### Fixes

- Cmd-Tab to an app on another workspace brings that app's window to the front when you get there. Before, another app could stay in front, and for an app with windows on several workspaces dinky could go to the wrong one.

## 0.11

### Fixes

- Obsidian and other Electron apps tile again. Their windows could keep a slot in the layout while staying where they were, with other windows tiling around the empty slot.

## 0.10

### Scripting

- `dinky list-modes --current` prints the binding mode dinky is in, and `mode-changed` hooks get `$DINKY_MODE` and `$DINKY_PREV_MODE`, so a bar can show the mode.

### Menu

- Clear Saved Minimum Sizes in the menu, or `dinky clear-minimum-sizes`, forgets the minimum window sizes dinky has learned for each app, so windows can tile smaller again after an app lowers its minimum.

## 0.9

### Menu

- The menu bar menu has every command: focus, move, join, resize, layout, displays and modes as well as workspaces. Each item shows the key bound to it, and bindings no item covers are listed under Other Key Bindings.

## 0.8

### Fixes

- Sleeping and waking, or anything else that makes displays drop out and come back, no longer piles other workspaces' windows onto workspace 1. Once the displays settle, each window goes back to its workspace.
- After displays come or go, windows that apps moved around on hidden workspaces snap straight back into their tiles when you next visit, instead of gliding in from wherever the app put them.
- `workspace prev` and `workspace next` no longer get stuck on a display with nothing on it. A display focused with `focus-monitor` or `focus --boundaries all-monitors-outer-frame` stops counting as focused once dinky focuses a window or a display comes or goes, even when that window had focus before.

## 0.7

### Fixes

- Unplugging the display dinky was animating on no longer leaves windows stuck mid-glide at odd sizes. Animations continue on the display that is main now, and a glide that stalls for any other reason lands its windows within a couple of seconds.

## 0.6

### Motion

- Windows take about 150 ms to glide to their tiles by default, up from 50. Set `[animations] duration-ms` to change it.

### Fixes

- The minimum sizes dinky learns for an app are kept across quits and `enable off`; restoring windows no longer overwrites them with the ones from launch.
- A new window that reuses a closed window's id is tiled instead of being left where it opened.
- When macOS moves a display's Spaces to another display, their layouts move with them instead of starting over.
- A minimized window keeps its border, hidden, instead of getting a new one when it comes back.
- `move-window-to-display --follow` focuses the moved window as reliably as `move-window-to-workspace --follow` does, instead of sometimes leaving the layout behind on the old window.
- `dinky help` says what `enable off` does: it stops tiling and restores every window.

## 0.5

### Motion

- Windows glide to their tiles instead of jumping. Set the speed with `[animations] duration-ms` (50 by default) or turn it off with `enabled = false`. It's off while macOS's Reduce Motion is on.
- While you drag a tiled window, dinky outlines the tile it came from and the tile it will swap with. The window now swaps with the tile under the pointer, not the one under its centre. `[drag] placeholders = false` turns the outlines off.

### Layouts

- `flatten-workspace-tree` puts windows back into the workspace's configured layout: a fixed grid gets its cells back, and an accordion workspace becomes an accordion again.
- `move` past the edge of an accordion that fills the workspace takes the window out of it, into a tile beside the accordion, as in AeroSpace.

### Other

- dinky warns when another window manager is also running, with a `!` in the menu bar, a line in the menu and in `dinky doctor`. Two window managers undo each other's layouts, which looks like dinky failing to tile.
- The update window shows what changed, and every release is listed at [dinky.rodeo/changelog](https://dinky.rodeo/changelog/).

### Fixes

- Clicking between two windows of the same app moves focus and the border to the window you clicked.
- A window put into native full screen, or slow to finish a resize, no longer teaches dinky that its app can't shrink. That could leave every window of the app filling the screen.

## 0.4

**Upgrading:** workspaces are now numbered across all displays. `workspaces` is the total rather than a count per display, and `workspaces` inside `[display.<pattern>]` is now a config error. Use `[workspace-to-display]` to put a workspace on a particular display.

### Workspaces

- Workspace numbers stay put when you dock or undock. Each workspace is one Space, on the main display unless `[workspace-to-display]` places it elsewhere.
- dinky removes Spaces it no longer needs instead of letting leftovers pile up.
- Tiled windows keep their layout when their workspace moves to another display.
- `workspace N` goes to whichever display the workspace is on; `workspace prev` and `next` step through the focused display's workspaces.
- Queries, hooks and the menu bar use the new global numbers.

### Layouts

- New `fixed` layout: give a workspace a grid with `[workspace.N]` `columns` and `rows`. New windows fill empty cells without resizing the others; when the grid is full, `expand` adds a column, adds a row, or stacks windows in the last cell.
- `default-tiling = false` leaves workspaces untiled unless a `[workspace.N]` table turns tiling on.
- `dwindle` is accepted as another name for the `tiles` layout.

### Fixes

- Cmd-Tab to Helium and Safari web apps switches Spaces again.
- `workspace-back-and-forth` returns to the workspace you were on, not a Space you swiped past.
