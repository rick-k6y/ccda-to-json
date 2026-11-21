# ccda-to-json

Declarative pipeline for transforming HL7 C-CDA documents into JSON and CSV using `xq` and `jq`.

## Overview
This repository demonstrates a lightweight, declarative approach to C-CDA parsing. Instead of writing complex imperative code, we use `xq` (from the Python `yq` package) to handle the XML-to-JSON translation, and `jq` to map the resulting JSON to our desired schema.

## Usage
Ensure you have `yq` (which provides `xq`) and `jq` installed.

```bash
./extract_patient.sh samples/sample_ccda.xml
```

## Dependencies and installation

This script uses `xq` from the **Python `yq` package** (by kislyuk), plus
`jq`. The Python package provides both `yq` and `xq`; similarly named
packages from other sources may be different tools.

On Debian/Ubuntu, install `jq` and `pipx`:

```bash
sudo apt update
sudo apt install jq pipx
```

Install the Python package with `pipx`:

```bash
pipx ensurepath
pipx install yq
```

Open a new terminal, then verify the commands are available:

```bash
command -v xq
xq --version
```

Run the extractor:

```bash
./extract_patient.sh examples/sample_ccda.xml
```

`pipx` keeps the Python package isolated from the system Python while making
its commands available in your user PATH. It is not recommended to install using `sudo pip`
or to use `--break-system-packages`.

## Sample data attribution

The C-CDA XML files in `examples/` are sourced from
[jddamore/ccda-samples](https://github.com/jddamore/ccda-samples).
That project says its samples were copied from the
[ONC 2015 C-CDA Certification Samples](https://github.com/siteadmin/2015-C-CDA-Certification-Samples)
repository and describes the original documents as having been entered into the public domain there.

These files are included as test fixtures. The MIT license in this repository
covers project code; sample files retain their upstream provenance and any
applicable terms.

