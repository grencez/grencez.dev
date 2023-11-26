---
canonical_url: https://grencez.dev/2015/getting-by-with-git-20151107
date: 2015-11-07
description: How to use Git for version control in the most basic way possible.
last_modified_at: 2023-11-26
---

# Getting by with Git

Date: 2015-11-07

Update: 2023-11-26

This tutorial introduces just enough Git commands to make a project.
Be aware that it uses `trunk` as the main branch instead of `master`.

- [Global Settings](#config-global)
- [Making a Remote Repository](#init-remote)
- [Basic Commands](#commands)
- [A Note on Commit Messages](#commit-messages)

## Global Settings {#config-global}

It is important for people to know who you are when committing changes.
Create a file `~/.gitconfig` (by typing `git config --global -e` in a terminal) to contain some minimal information about yourself like:

```
[user]
  name = Alex Klinkhamer
  email = git@grencez.dev
[push]
  default = matching
```

If sharing your real email address on every commit feels weird, note that it can be fake.
However, if going down this route, consider using a [noreply address from GitHub](https://docs.github.com/en/free-pro-team@latest/github/setting-up-and-managing-your-github-user-account/setting-your-commit-email-address) to associate your commits with you (or at least to your GitHub account).

## Making a Remote Repository {#init-remote}

Code shouldn't just be stored on one machine because the hard drive may crash or we may have multiple work machines.
Therefore, we should make a repository on a server that all of our machines can access.
Let's assume you want to make a project named `$proj` and store a copy of it on a remote server at `$remote_url` like:

```shell
proj=my_awesome_project
remote_url=grencez@myserver.net:~grencez/repo/$proj.git
```

In this case, the `$remote_url` is hosted on an SSH-accessible server, but it could be a path on your local machine like `$HOME/repo/$proj.git`.
If it's a GitHub URL like `git@github.com:grencez/lace.git`, then just use GitHub to create the repository and skip this section.

Let's create `$remote_url` repository used in this example.
First SSH in:

```shell
ssh grencez@myserver.net
mkdir -p ~/repo/$proj.git
cd ~/repo/$proj.git
```

**Private.**
If this is a project just for you, then all we need to do is initialize the repository.

```shell
git init --bare
```

**Public.**
If this is a project should be shared with everyone on the remote machine, we must allow people to get to the repository and make it readable and writable by everyone.

```shell
chmod a+x ~/ ~/repo
git init --bare --shared=0666
```

**Shared with Group.**
Usually a public repository isn't the greatest idea because anyone on the machine can mess with your code.
If you have the luxury of having a group containing all members, we can restrict access to the group.
Let it be defined as `group=my_group`.

```shell
chmod a+x ~/ ~/repo
chgrp $group .
chmod g+rwxs .
git --bare init --shared=group
```

## Basic Commands {#commands}

This section describes the minimal amount of knowledge you need to use git.
Note that some commands (`git pull` and `git push`) assume some default values which were set by `git clone`.

### Check out Code

Back on your own machine, get a copy of the repository using `git clone`.

```shell
mkdir -p ~/code
cd ~/code
git clone $remote_url
cd $proj
```

After this initial clone, it is simple to pull changes other people have made.

```shell
git pull
```

### Check in Code

To add a new file to version control:

```shell
echo "# $proj has begun!" > README.md
git add README.md
```

To see what files have been added, modified, or are not tracked by git, use the status command.

```shell
git status
```

To commit all of your changes:

```shell
git commit -a
```

This will open an editor so you can explain your changes in a *commit message*.
The editor is determined by the `$EDITOR` environment variable, which is probably `nano` by default... pretty easy to use.
If you only have a short message and don't want to work in an editor, the message may be specified directly.

```shell
git commit -a -m 'Add README'
```

One can also change the most recent commit or its message (**ONLY DO THIS IF THE COMMIT HAS NOT BEEN PUSHED**).

```shell
git commit -a --amend
```

Finally, push your changes to the repository, otherwise nobody will see them!
When it's the first commit, you generally need to specify a push location and branch like `git push origin master`.
I tend to [prefer](https://grencez.dev/2020/git-trunk-20200914) a `trunk` branch instead of the default `master` one since it matches Subversion terminology.
Setting that up is a couple of extra commands but is pretty hassle free afterwards:

```shell
git branch -M trunk
git push -u origin trunk
git push origin trunk
```

For all pushes after the first one, `origin` and `trunk` are implied.

```shell
git push
```

If you still need the `origin` and `trunk` arguments, you can set the defaults in an editor with `git config -e` or directly like:

```shell
git config branch.trunk.merge refs/heads/trunk
git config branch.trunk.remote origin
```

To see other options:

```shell
git config -l
```

### Misc File Operations

Add file, remove file, move file, or discard changes.

```shell
git add new-file.c
git rm unwanted-file.c
git mv old-file.c new-file.c
git checkout HEAD file-with-changes.c
```

If you previously added a file and want to remove it, you must be rather forceful.

```shell
git rm -f --cached unwanted-file.c
```

See previous commit messages.

```shell
git log
git log --follow file-that-has-moved.c
```

### Working with Others

The above instructions are fine for working by yourself, but what about when others are making changes concurrently?
In short, make sure trunk has a linear history by working on branches and only squash merging to it.

```shell
git pull upstream trunk
git checkout stage
git merge trunk
# Note your commit message and redo it.
git reset --soft trunk
git commit -a -S
# We rewrote history. Time to force push.
git push -f origin stage
```

## A Note on Commit Messages {#commit-messages}

Most commits do warrant some description.
Imagine if your changes broke something, and someone else (or "future you") is tasked with fixing it.
Without a meaningful commit message to read, that person doesn't know your intent in making those original changes, and their change may break something else!
(Side note: Use tests to protect your code from others.)

A commit message should be formatted with the first line being a short description (cut off at 50 characters), followed by an empty line, and then more detailed explanation.
I tend to prefer small code changes these days, with most documentation in examples and tests, leaving the commit messages to explain why code is being changed how it is.

My **old style** noted what changed where.
It served me well for a long time, so here's an example:

```
Add normal mapping to raytracer

1. In the raytraced version, one can now specify a normal map in
   object coordinates to give the illusion of a more complex surface.
  a. material.c/h  map_normal_texture()
  a. wavefront-file.c  readin_wavefront()
  a. raytrace.c  fill_pixel()
     - This function is getting too complicated...

2. When determining the normal of the track's surface, be sure the damn
   thing is normalized! This only affects tracks without vertex normals.
  b. motion.c  apply_track_gravity()

3. Clean up some parse code with the addition of a new macro.
  a. util.h  AccepTok()
  c. wavefront-file.c
    + readin_wavefront()
    + readin_materials()
  c. dynamic-setup.c  readin_Track()
```

Changes are described in order of priority and hierarchically by: intent (number prefix), file (letter prefix), function or class (`+' prefix, or on same line if there's room), and extra description (`-' prefix).
The letter prefixes signify the type of change: `c` means change code, `b` means bug fix, `a` means add code (new functionality), `r` means remove code, and `d` means comment/documentation changes (if the file also contains code).
The letters may be a bit pedantic (former colleagues used a `*' prefix instead).

