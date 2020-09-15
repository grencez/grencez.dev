
# Creating a Git repository whose default branch is named "trunk"

Date: 2020-09-14

GitHub will soon start preferring that default branches are named [main](https://github.com/github/renaming#why-main) instead of master.
I'd like to have my new project's default branch named trunk.
It might make sense to rename the branch for other projects too.

## Initializing

I tried initializing a repository with `git init --initial-branch trunk`, but my version of Git doesn't support that flag yet.
It looks like running `git branch -M trunk` after the initial commit is (roughly?) equivalent.
Here's approximately how I made the initial commit for https://github.com/grencez/fantasma:

```shell
mkdir fantasma
cd fantasma
git init
echo "# Fantasma" > README.md
git add README.md
git commit -m "Add README"
git branch -M trunk
git remote add origin git@github.com:grencez/fantasma.git
git push -u origin trunk
```

## Renaming

It's pretty easy to rename master to trunk as well if you don't have pull requests referencing it.
I did this for https://github.com/grencez/website:

```shell
cd website
# Create and checkout a new trunk branch.
git checkout -b trunk
# Push it upstream.
git push git@github.com:grencez/website.git trunk
# Delete local master branch.
git branch -d master
```

Then I changed the default branch to "trunk" on GitHub and deleted "master".
