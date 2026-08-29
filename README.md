# experiment

`experiment` creates an isolated Python workspace for rapid local experimentation. It sets up a virtual environment, Jupyter notebook, `.env` file, and optional dependencies.

## Requirements

The script requires Bash, Python 3, the standard-library `venv` module, and internet access for installing Python packages.

## Installation

Run the installer:

```bash
curl -fsSL https://raw.githubusercontent.com/RAMCloudCode/experiment-venv/main/install.sh | sh
```

It installs to `/usr/local/bin` when writable and otherwise falls back to
`~/.local/bin`, adding that directory to your shell profile when necessary.

Alternatively, copy the script manually to a directory on your `PATH` and make
it executable:

```bash
mkdir -p ~/.local/bin
cp experiment ~/.local/bin/experiment
chmod +x ~/.local/bin/experiment
```

Ensure `~/.local/bin` is included in `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

To make that change persistent, add the export command to `~/.bashrc`.

## Usage

```text
experiment [options] [working-directory]
```

When no working directory is provided, the current directory is used.

```text
Options:
  -e, --env ENV_DIR
      Virtual environment directory.

  -n, --notebook NOTEBOOK
      Notebook filename.

  -r, --requirements REQUIREMENTS
      Requirements file.

  -h, --help
      Show help.
```

## Defaults

```text
Working directory: current directory
Environment:       .experiment
Notebook:          experiment.ipynb
Requirements:      requirements.txt in the working directory, when present
```

## Examples

Create an experiment workspace in the current directory:

```bash
experiment
```

Create one in another directory:

```bash
experiment ~/dev/example-project/experiments
```

Use custom environment and notebook names:

```bash
experiment \
  --env .email-test \
  --notebook email-test.ipynb \
  ~/dev/example-project/experiments
```

Install dependencies from a specific requirements file:

```bash
experiment \
  --requirements ../shared/requirements.txt \
  ~/dev/example-project/experiments
```

Relative paths supplied through `--requirements` are resolved from the directory where the command was invoked. When the option is omitted, the script uses `requirements.txt` from the selected working directory when that file exists.

## Created files

A default invocation creates the following structure:

```text
.
├── .experiment/
├── .env
├── .gitignore
└── experiment.ipynb
```

The virtual environment includes:

```text
ipykernel
python-dotenv
jupyterlab
```

The starter notebook contains:

```python
import os
from dotenv import load_dotenv

load_dotenv()
```

The script creates `.env` only when it does not already exist. 
It creates or updates `.gitignore` with entries for the generated virtual environment, `.env`, and `.ipynb_checkpoints/`.

If the specified virtual environment or notebook path already exists, the script exits without replacing it.
If environment setup fails, the incomplete virtual environment is removed.

## Using the workspace

The script prints commands for activating the environment and launching JupyterLab after setup completes.

Activation is optional when an editor such as VS Code is configured to use the generated environment directly.

To activate it manually:

```bash
cd "/path/to/working-directory"
source ".experiment/bin/activate"
```

To launch JupyterLab without activation:

```bash
cd "/path/to/working-directory"
".experiment/bin/jupyter" lab "experiment.ipynb"
```
