#!/usr/bin/env bash

# Check if a file was provided
if [ -z "$1" ]; then
    echo "Usage: $0 <path-to-ccda.xml>"
    exit 1
fi

INPUT_FILE="$1"

# Check if the file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File '$INPUT_FILE' not found."
    exit 1
fi

# Use xq (from the yq package) to convert the C-CDA XML to JSON.
# The -p=xml flag tells xq to parse XML. 
# We then pipe that JSON into jq to extract the patient demographics.
xq -p=xml '.ClinicalDocument.recordTarget.patientRole.patient | {
    first_name: .name.given."#text",
    last_name: .name.family."#text",
    dob: .birthTime."@value",
    gender: .administrativeGenderCode."@displayName"
}' "$INPUT_FILE"
