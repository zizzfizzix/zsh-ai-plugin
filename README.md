# at-command

An [oh-my-zsh](https://ohmyz.sh/) plugin that transforms natural language requests into executable shell commands using [Claude Code](https://claude.ai/code). Inspired by [iafan](https://github.com/iafan/at-command).

Your request is converted to a ready-to-run command and placed in the zsh buffer so you can review (and optionally edit) it before pressing Enter.

## Requirements

- [oh-my-zsh](https://ohmyz.sh/)
- [Claude Code CLI](https://claude.ai/code) installed and authenticated (`claude`)

## Installation

1. Clone or copy the `at-command` directory into your oh-my-zsh custom plugins folder:

   ```sh
   git clone https://github.com/zizzfizzix/zsh-ai-plugin \
     ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/at-command
   ```

   Or manually copy `at-command.plugin.zsh` into a new folder `~/.oh-my-zsh/custom/plugins/at-command/`.

2. Add `at-command` to the plugins list in `~/.zshrc`:

   ```sh
   plugins=(... at-command)
   ```

3. Reload your shell:

   ```sh
   source ~/.zshrc
   ```

## Updating

```sh
git -C ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/at-command pull
source ~/.zshrc
```

## Usage

```sh
@ <natural language request>
```

### Examples

```sh
@ list all jpg files larger than 5mb
@ show my ipv4 address
@ find and kill the process on port 3000
@ compress this directory into a tar.gz
@ show disk usage sorted by size
```

The generated command appears in your zsh buffer — review it, then press Enter to run (or edit it first).

## Configuration

| Variable            | Default        | Description                    |
| ------------------- | -------------- | ------------------------------ |
| `AT_COMMAND_MODEL`  | `haiku`        | Claude model to use            |
| `AT_COMMAND_PROMPT` | `~/.at_prompt` | Path to the system prompt file |

Set these in your `~/.zshrc` before the `plugins=(...)` line, e.g.:

```sh
export AT_COMMAND_MODEL=opus
export AT_COMMAND_PROMPT=~/.config/at_prompt
```

### System Prompt

On first use, a default system prompt is created at `~/.at_prompt`. You can customize it to tailor command generation for your environment (e.g. preferred tools, aliases, or coding style). Your platform and shell are detected and injected automatically.

## Warning

> **Always review the generated command before running it.**
> LLMs can make mistakes, especially with file operations or deletions.
