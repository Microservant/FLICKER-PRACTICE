
gist.el -- Emacs integration for gist.github.com
================================================

Uses your local GitHub config if it can find it.

Go to your [GitHub Settings](https://github.com/settings/tokens) and generate
a personal access token with at least `gist` scope. If you intend to use more
of the underlying `gh.el` library, it's recommended you also add the `user` and
`repo` scopes.

Next run:

``` Shell
git config --global github.user <your-github-user-name>
git config --global github.oauth-token <your-personal-access-token-with-gist-scope>
```

News
====

What's new in 1.4.0 ?
---------------------

* support #tags in gist description
* support limiting display by tags, visibility

What's new in 1.3.0 ?
---------------------

* support listing another user's gists
* more keybindings for (un)starring, forking gists
* optionally ask for description at gist creation time

What's new in 1.2.0 ?
---------------------

* make gist list appearance customizable