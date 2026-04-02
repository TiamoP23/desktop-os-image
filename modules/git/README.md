# git module

Clones a remote Git repository into a destination directory during image build.

## Options

- `repo` (required): Remote repository URL.
- `dest` (required): Destination directory path in the image filesystem.
- `branch` (optional): Branch, tag, or ref name to clone.

## Usage

```yaml
modules:
  - type: git
    repo: https://github.com/example/my-dotfiles.git
    branch: main
    dest: /usr/share/my-dotfiles
```
