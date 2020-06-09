
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
* more robust mode detection
* add ability to open gist without changing focus
* add ability to open current gist in browser

What's new in 1.1.0 ?
---------------------

* support for multiple profiles (e.g. github.com and Github Enterprise instance)
* remove calls to deprecated gh.el APIs
* support for background-reloading of gist list

What's new in 1.0 ?
-------------------

* gist.el now maintains a local cache so as to not go to the gist server every now and then.
* multi-files gist support (indicated by a '+' in the gist list)
* improved gist-list buffer, based on tabulated-list.el (same codebase as package.el)
    New keybindings:
    * `g` : reload the gist list from server
    * `e` : edit current gist description
    * `k` : delete current gist
    * `+` : add a file to the current gist
    * `-` : remove a file from the current gist
    * `y` : print current gist url
    * `b` : browse current gist
    * `*` : star gist