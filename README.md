# ccda-to-json

Declarative pipeline for transforming HL7 C-CDA documents into JSON and CSV using `xq` and `jq`.

## Overview
This repository demonstrates a lightweight, declarative approach to C-CDA parsing. Instead of writing complex imperative code, we use `xq` (from the Python `yq` package) to handle the XML-to-JSON translation, and `jq` to map the resulting JSON to our desired schema.

## Usage
Ensure you have `yq` (which provides `xq`) and `jq` installed.

```bash
./extract_patient.sh samples/sample_ccda.xml
```
