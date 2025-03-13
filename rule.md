# If you want to see the directory tree

use `tree` command

# If you want to use a git command

use `--no-pager` option by default

# Before creating a new feature

## Check if the feature already exists (duplications)

- Check if the feature already exists in the codebase
- Check if the feature is already implemented in the framework
- Check if the feature is already implemented in the third-party libraries

### If it is already implemented:

1. Summarize briefly the features
2. Choose the best one
3. Remove the duplication

## Check if some of the features can be leveraged in codebase.

# After creating a new feature

## Check if the feature is implemented right

- Check the syntax of the feature
- Check the logic of the feature
- Check the error handling of the feature

# Before removing a feature

## Check if the feature is used in codebase

- Check if the feature is used in the codebase
- Check if the feature is used in the framework
- Check if the feature is used in the third-party libraries

### If it is used:

1. Check if the feature can be removed
2. If the feature can be removed, remove it
3. If the feature cannot be removed, leave it
