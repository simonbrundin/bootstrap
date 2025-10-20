## Why
The bootstrap script fails with directory creation and git clone errors when the repos directory or simon-cli repository already exist, preventing users from re-running the bootstrap process successfully.

## What Changes
- Update bootstrap.sh to use `mkdir -p` for the repos directory creation
- Add conditional logic to check if simon-cli directory exists and handle accordingly (pull if git repo exists, clone if not)

## Impact
- Affected code: bootstrap.sh
- No breaking changes - improves robustness of bootstrap process
- Allows bootstrap to be run multiple times without errors