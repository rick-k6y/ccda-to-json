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
xq '
def xmltext:
  if type == "array" then (.[0] | xmltext)
  elif type == "object" then (.["#text"] // "")
  elif . == null then ""
  else tostring
  end;

def dateparse:
  if . == null or . == "" then "Unknown"
  else tostring as $d
  | if ($d | test("^[0-9]{8}")) then $d[0:8]
    elif ($d | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}")) then ($d[0:10] | gsub("-"; ""))
    elif ($d | test("^[0-9]{4}/[0-9]{2}/[0-9]{2}")) then ($d[0:10] | gsub("/"; ""))
    elif ($d | test("^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$"))
      then try ($d | strptime("%m/%d/%Y") | strftime("%Y%m%d")) catch "Unknown"
    else "Unknown"
    end
  end;

def propercase:
  tostring
  | ascii_downcase
  | split(" ")
  | map(if length > 0 then (.[0:1] | ascii_upcase) + .[1:] else . end)
  | join(" ");

def canonical_gender:
  if . == null or . == "" then "Unknown"
  else
    ascii_upcase as $g
    | if $g == "M" or $g == "MALE" then "Male"
      elif $g == "F" or $g == "FEMALE" then "Female"
      else "Unknown"
      end
  end;

def primary_phone:
  if . == null then []
  elif type == "array" then .
  else [.]
  end
  | map(select(."@use" == "HP") | ."@value" // "")
  | map(
      try
        (match("\\+?\\(?[0-9][0-9(). -]*[0-9]") | .string)
      catch ""
    )
  | first // "Unknown";

.ClinicalDocument.recordTarget.patientRole as $role
| $role.patient
| {
    first_name: (.name.given | xmltext | propercase),
    last_name: (.name.family | xmltext | propercase),
    dob: (.birthTime["@value"] | dateparse),
    gender: (
      .administrativeGenderCode["@displayName"]
      // .administrativeGenderCode["@code"]
      | canonical_gender
    ),
    primary_phone: ($role.telecom | primary_phone)
  }
' "$INPUT_FILE"
