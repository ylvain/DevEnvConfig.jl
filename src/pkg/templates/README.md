<!-- 
Note: even if this package is configured to use a GitHub repo name
of the form PACKAGE (and *not* PACKAGE.jl), we still use the form
PACKAGE.jl for the main title of the README.
It is recommended to keep this convention as this is what users may
google for... (likewise for the sitename of the documentation)
-->

# {{{PKG}}}.jl - *A Julia Package for something cool*

{{#BADGES}}
{{{.}}}
{{/BADGES}}

---

A few things you should do for this project...
* Write some more details about it right here !
* Provide some informations in the GutHub `About` section in the right column.
* You should have a CodeCov account, if not, you can create one in 3 clicks...
    * Go to the [sign-up page](https://about.codecov.io/sign-up/)
    * Select `GitHub` as the Code Host
    * Authorise access and give you GitHub password, done.
{{#REMOTE_DOC}}
* Check that you have setup the doc deployment key (see below).
{{/REMOTE_DOC}}
{{#PRIVATE_REPO}}
* This is a private repo! You need to allow CodeCov to work with it (see below).
{{/PRIVATE_REPO}}
{{^PRIVATE_REPO}}
!!! Note that this package has been setup to upstream to a GitHub public repo.
If this repo is actually private, you should probably regenerate the package!
{{/PRIVATE_REPO}}

<!-- 
Some note to clean-up
* The Badge Doc:Stable will link to 404 until you have published at last one release (right column)
* The Badge Doc:Dev link to 404 until you have run it MANUALLY 
    * Todo add comments in Documenter.yml to enable on main commit (but explain that it cost minutes...)
    * In the doc setup, provite link to e.g. https://github.com/ylvain/Pk2.jl/actions/workflows/Documenter.yml
    * Run the doc manully to check deployment...
    * Explain that once deployed, the doc still need to be published by GitHub to the github.io site (wait or go see in the https://github.com/ylvain/PkDoc/deployments if it is publised)
* The Tests and Coverage run for each commit on `main`, for each pull request to `main` and can also be run manually
* The documentation has "Edit on GitHub" that links to https://github.com/ylvain/Pk2.jl/blob/master/docs/src/index.md#. master is not the correct branch... Links works but only because GitHub redirect to main
* Add some lines of codes in /src and some testset in /runtests, allows to check better doc and coverage
* If deploy doc to SAME repo, but as section telling how to enable GitPages on gh-pages (only after first run of documentation otherwise the bransh gh-pages is not yet created)
 -->


{{#REMOTE_DOC}}

---

<!-- START OF HOW-TO SECTION - YOU SHOULD DELETE THIS -->
## How to setup documentation deployment
This repo will deploy documentation to [{{{REMOTE_DOC}}}]({{{REMOTE_DOC_URL}}}).
The action `Documenter` build and deploy the doc.
You can trigger it manually to test the deployment.
To allow deploying from this repo to the remote repo:
* Step 1: create a write access key on the remote repo:
    * You only need to do this once. If you already have added the *public* `Documenter deploy` key for another repo, you can go directly to step 2.
    * Go to [{{{REMOTE_DOC}}}]({{{REMOTE_DOC_URL}}})
    * Click tab `Settings`, `Deploy keys`, button `Add deploy key`
    * Set the `Title` to `Documenter deploy` for information
    * Set the `Value` to the SSH *public* key string (of the form `ssh-rsa 6sFaNrOesLN8O...MxUUX= name-of-key`)
    * Check `Allow write access` and click `Add key`
* Step 2: create a secret storing the key on *this* repo
    * Go the [secret store]({{{GITHUB_PKG_SETTING_SECRETS}}}) of *this* repo on GitHub (tab `Settings`, `Secrets`)
    * Click this button `New repository secret` 
    * Set the `Name` to *exactly* `DOCUMENTER_KEY`
    * Set the `Value` to a *base64* encoding of the SSH *private* key string (of the form `QVlVUn...lS0tCg==`)
    * Click `Add secret`
<!-- END OF HOW-TO SECTION -->
{{/REMOTE_DOC}}


{{#PRIVATE_REPO}}
<!-- START OF HOW-TO SECTION - YOU SHOULD DELETE THIS -->
## How to setup CodeCov to work with a private repo
* Step 1: allow CodeCov to list your private repositories (needed once)
    * Go to your [CodeCov repo list]({{{CODECOV_HOME}}})
    * Go to the tab `Repos`, it lists the `Enabled` repo for which you already have coverage analysis
    * Click the `enable private` blue link on the right and grant the access
    * Click the `Not yet setup` button on the right
    * This now list all your GitHub repo, public and private, that are not yet `Enabled`
    * Note: as soon as GitHub publish a code coverage for repo, it will become `Enabled`
    * You can now go to the [CodeCov settings]({{{CODECOV_PKG_SETTING}}}) of *this* repo (or just click it in the list)
* Step 2: allow CodeCov to read the sources to display coverage
    * In the [CodeCov settings]({{{CODECOV_PKG_SETTING}}}) page of *this* repo,
    * Copy the `Repository Upload Token` (this is a 35 characters string),
    * Go the [secret store]({{{GITHUB_PKG_SETTING_SECRETS}}}) of *this* repo on GitHub (tab `Settings`, `Secrets`)
    * Click this button `New repository secret` 
    * Set the `Name` to *exactly* `CODECOV_TOKEN`
    * Set the `Value` to the `Upload Token` string you've just copied from CodeCov
    * Click `Add secret`
* Step 3: allow CodeCov to display the coverage Badge on this REAME
    * In the [CodeCov settings]({{{CODECOV_PKG_SETTING}}}) page of *this* repo,
    * Copy the `Repository Graphing Token` (this is a 10 characters string),
    * Edit *this* README file, near the top, in the URL of the `[Coverage]` badge,
    * Replace the placeholder `?token=SOME_10_CHARS_STRING` by the actual token string.
<!-- END OF HOW-TO SECTION -->
{{/PRIVATE_REPO}}

{{#HAS_CITATION}}
## Citing

See [`CITATION.bib`](CITATION.bib) for the relevant reference(s).
{{/HAS_CITATION}}
