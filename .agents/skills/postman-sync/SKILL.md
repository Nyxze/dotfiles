---
name: postman-sync
description: Sync the current repo's routes (generated go-swagger spec) into Alexy's local Postman collections, one collection per project. Use when the user says "sync postman", "postman-sync", "mets à jour Postman", or has just added/changed a route in a go-swagger repo (crm-mgr, edito-mgr, fireball…) and wants it in Postman.
---

# postman-sync

The script `postman-sync` (in `~/work/postman`, on PATH) does the work. This skill only decides when and how to call it, and reports the result.

## What it does

- Regenerates the repo's Swagger 2.0 spec with the repo's own `swagger generate spec` line from its Makefile (into a temp file, `swaggerfiles/` is untouched).
- Converts it with `postman spec generate collection` (same conversion as a Postman import).
- `~/work/postman` is the `postman/` folder of a Postman workspace connected to `~/work` (Local Files > Open Folder), so the app shows these files in its Local view.
- Merges it into the collection `~/work/postman/collections/<repo dir name>/`, with folders following the URL path (Postman's Paths layout), matching requests on METHOD + URL path:
  - `+` new route: created exactly as the spec describes it, body included. The body is never "fixed": if the spec and the code disagree (e.g. a missing wrapper key), that is a bug to catch, not to hide.
  - `~` existing route: name, description and folder follow the spec; body, headers, query values, auth and scripts keep the user's edits.
  - `?` route no longer in the spec: reported, never deleted.
- `{{baseUrl}}` is a variable on the project collection, `http://localhost:<port><basePath>`. The port is read from the repo (default of the server port flag in `commands/server.go`, following the constant it names). It is only written when the collection is created.
- Local only: nothing is pushed to the Postman cloud.

## How to run it

1. Run it on the repo the user is working in (any folder inside it works):
   ```bash
   postman-sync . --dry-run
   ```
   Show the user the `+`, `~` and `?` lines and the totals.
2. Run it for real (no confirmation needed: it only writes the local collection and never deletes):
   ```bash
   postman-sync .
   ```
3. Report what changed in a few lines. Call out every `?` (route gone from the spec) and every `!` (duplicate), since those need a human decision.

## When it fails

- `bin/swagger not found`: the repo needs `make dep`.
- `not a go-swagger repo`: the repo has no `swagger generate spec` in its Makefile, there is nothing to sync.
- `warning: no port found`: the collection gets `http://localhost<basePath>`; tell the user to set `baseUrl` on the collection in Postman.
- `collection lint failed`: show the lint output. It is usually a request edited by hand in a way Postman would not write (e.g. URL query and `queryParams` out of sync).

## Never

- Never push to the Postman cloud (no `-w`, no `workspace push`) unless the user explicitly asks: the Postman account is shared with the team.
- Never delete requests or folders from the collection on the user's behalf.
- Never put a token in the collection files. Tokens belong in the user's `localhost_alexy` environment.
