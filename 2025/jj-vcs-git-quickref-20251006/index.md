---
canonical_url: https://grencez.dev/2025/jj-vcs-git-quickref-20251006
date: 2025-10-06
last_modified_at: 2025-10-06
description: How to work with a git repository using jj.
---

# Quickref: Jujutsu with Git version control
Date: 2025-10-06

## Install
Go to [https://github.com/jj-vcs/jj/releases/latest](https://github.com/jj-vcs/jj/releases/latest),
download the Linux musl tarball, untar it, and put the extracted `jj` executable in your `$PATH` (e.g., `~/bin/`).

### Config
My `~/.jjconfig.toml` looks like:
```toml
[user]
name = "grencez"
email = "git@grencez.dev"

[signing]
behavior = "drop"
backend = "gpg"
key = "A1351B111E640817"
```

## Initialize
```shell
# Clone a Git repository, like the one for this website.
jj git clone git@github.com:grencez/grencez.dev.git
cd grencez.dev
# Pull new changes from origin.
jj git fetch
# Read the docs.
jj help
```

## Navigate
```shell
# Show revisions in the local repo.
git log  # Not the same as `jj l`!!!
jj log REV1::REV2 --stat  # See changes with file info from REV1 to REV2.
# Switch to a revision named REV.
jj edit -r REV  # Only need to type the first letter or few of REV.
# Show what files have changed in this revision.
jj status
```

## Branch
```shell
# Create a fresh revision from trunk. Yours might be called "main" or "master".
jj new -r trunk
# Give it a description. "@" is the current revision.
jj describe -r @
# Create a local branch named "feat" corresponding to the revision.
jj bookmark create feat -r @
# Push the change.
jj git push -b feat --allow-new

# Create a fresh revision on top of the current one.
jj new -r @
# Give it a description after making some edits.
jj describe -r @
jj bookmark set feat -r @
jj git push -b feat
```

## Merge
```
# Show how we diverged from trunk.
jj log -r trunk::@
# Show only the revisions in between @ and trunk.
jj log -r trunk+::@-
# Squash those revisions into the current one to retain a clean history.
jj squash --from trunk+::@- --into @

# Pull any new changes made to trunk.
jj git fetch
jj rebase -s @ -d trunk

# If everything looks good, sign it and push to feat!
jj sign -r @
jj git push -b feat

# If everything still looks good, set trunk to that revision.
jj bookmark set trunk -r @
jj git push -b trunk

# Delete the branch.
jj bookmark delete feat
jj git push --deleted
```

## Oneoff
```shell
# Discard changes to a given file.
jj restore FILEPATH

# Create a new revision based on a given parent.
jj new -r ANCESTOR_REV
# Associate a revision with a different parent.
# I often rebase onto "trunk" to decouple unrelated revisions.
jj rebase -s REV -d DIFFERENT_ANCESTOR_REV

# Squash one revision's changes into another.
jj squash -k --from REV1 --into REV2 FILEPATH1 FILEPATH2
# If no files are given, all are squashed.
# The -k flag keeps REV1 even if it becomes empty.

# Add another remote named "work".
jj git remote add work git@github.com:gendeux/tmp_grencez.dev.git
# Fetch changes from all remotes.
jj git fetch --all-remotes

# Claim authorship of the current revision.
jj metaedit --update-author --update-author-timestamp -r @

# Undo an operation.
jj op revert
```
