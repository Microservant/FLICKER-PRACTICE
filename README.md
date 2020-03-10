
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
