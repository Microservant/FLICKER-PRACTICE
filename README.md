
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
    * `^` : unstar gist
    * `f` : fork gist
* in-place edition. While viewing a gist file buffer, you can:
    * `C-x C-s` : save a new version of the gist
    * `C-x C-w` : rename some file
* dired integration. From a dired buffer, you can:
    * `@` : make a gist out of marked files (with a prefix, make it private)

Install
=======

Dependencies
------------

gist.el depends on a number of other modules, that you'll need to install, either manually or by way of Emacs package manager

* tabulated-list.el
  built-in for emacs 24. If you're using emacs 23, you can find a backport here: https://github.com/sigma/tabulated-list.el
* gh.el
  GitHub client library. Install from there: https://github.com/sigma/gh.el
* pcache.el
  Really a gh.el dependency. Install from there: https://github.com/sigma/pcache
* logito.el
  Really a gh.el dependency. Install from there: https://github.com/sigma/logito

Install gist.el from marmalade (recommended)
--------------------------------------------

In that scenario, you don't have to deal with the above dependencies yourself.

For emacs 24, first make sure http://marmalade-repo.org/ is properly configured. Then

    M-x package-install RET gist RET

For emacs 23, you'll need to install a version of package.el first. Some bootstrap code is available there: https://gist.github.com/1884169
Then proceed as for emacs 24. You might get some compilation errors, but the package should be operational in the end.

Install gist.el from git
------------------------

After installing the required dependencies, proceed with:

    $ cd ~/.emacs.d/vendor