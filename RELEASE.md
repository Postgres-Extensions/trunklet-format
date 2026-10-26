# RELEASE.md

This repo follows the shared release process in [`../ai/RELEASE.md`](https://github.com/Postgres-Extensions/ai/blob/main/RELEASE.md) (`make tag`, `make dist` and `make post-tag-version-bump` come from the vendored pgxntool 2.4.0). Local specifics only:

- **No release has a tag yet.** `0.1`, `0.1.0`, `0.1.1` and `0.2.0` exist as branches on upstream. Where shared step 1 compares against the previous release's tag, use the `0.2.0` branch (or PGXN.org).
- **Never create a tag named like one of those branches.** The ref becomes ambiguous and `git push origin <version>` fails with `src refspec <version> matches more than one`.
- **Both `default_version` and `META.in.json` are `stable` on master.** `make post-tag-version-bump` resets only the control file; set the `version` fields in `META.in.json` back to `stable` by hand in the same commit (shared step 8).
