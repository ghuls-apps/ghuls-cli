# Changelog
## Version 1
### Version 1.8.0
* Update to ghuls-lib 3.0.

### Version 1.7.2
* Require github-calendar in the gemspec.

### Version 1.7.1
* Use pessimistic version requirements.
* License as MIT.

### Version 1.7.0
* Add data provided by github-calendar (#2).

### Version 1.6.0
* Update dependency versions.
  * ruby: 2.2.3 -> 2.3.0
  * ghuls-lib: 2.2.3 -> 2.3.1
  * array_utility: 1.0.0 -> 1.1.0
* Remove unneeded dependencies, string-utility and octokit, as they are required by ghuls-lib.
* Replace Rainbow usage with Paint, because it is arguably simpler, and certainly faster.
* Clean up some code style issues.

### Version 1.5.0
* Data about issues, pulls, forks, stargazers, watchers, followers, following, and repository category totals is now available (#2).
* Now uses GHULS::Lib 2.2.0 and StringUtility 2.6.0, which provide a lot of performance improvements.
* array_utility is now a dependency because get_next will be removed from GHUS::Lib in its next version.
* Data for combined organization and personal repository languages is now available.

### Version 1.4.3
* Update to use ghuls-lib 1.2.1.
* Provides slightly more information.
* Will now analyze the organizations even if the user does not have any personal repositories.
* Data output uses the username given by the lib instead of the one entered in the arguments. This provides more accurate casing. For example, if you entered "programfox", it will use "ProgramFOX".

### Version 1.4.2
* Update to require ghuls-lib 1.1.3 for a major bug fix.
* Actually require certain minimum versions of things.

### Version 1.4.1
* Update to use ghuls-lib 1.1.1.

### Version 1.4.0
* Update to use new ghuls-lib gem.

### Version 1.3.0
* New -d --debug option to show a progress bar.

### Version 1.2.0
* Fix require_relative statement for utilities.rb, so it now actually works outside of the project root.
* Better error handling for authentication error (ProgramFOX)
* You can now get organization data for people other than yourself. It now checks if the user is a contributor to the org repos, rather than a collaborator, which was causing issues. (#19.)

### Version 1.1.0
* Organizations that the -g user contributed to are now supported.
* Better error-type-thing reporting.
* Catches Octokit::Unauthorized errors and returns false when initializing the client.
* Fix user_exists? error catching minor syntax bug.


### Version 1.0.2
* Actually fix load path stuff again.

### Version 1.0.1
* Fix load path stuff.

### Version 1.0.0
* Initial release
