# Project Agent Instructions

- Always run `xcodebuild -scheme whatEat -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build` before final response if any code changes were made.
- If the build fails, diagnose and fix the issue, then re-run until it passe
- Mention the exact `xcodebuild` command used in the final response if any code changes were made.
- On sign out, reset any locally stored app state (in-memory caches, view models, etc.) to avoid leaking data across accounts; tie new local storage to the sign-out flow.
