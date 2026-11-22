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
  else
    tostring as $raw
    | if ($raw | test("^[0-9]{8}")) then
        $raw[0:8]
      elif ($raw | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}")) then
        ($raw | match("^[0-9]{4}-[0-9]{2}-[0-9]{2}").string
         | strptime("%Y-%m-%d") | strftime("%Y%m%d"))
      elif ($raw | test("^[0-9]{4}/[0-9]{2}/[0-9]{2}")) then
        ($raw | match("^[0-9]{4}/[0-9]{2}/[0-9]{2}").string
         | strptime("%Y/%m/%d") | strftime("%Y%m%d"))
      elif ($raw | test("^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}")) then
        ($raw | match("^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}").string) as $date
        | if ($date | split("/")[0] | tonumber) > 12 then
            try ($date | strptime("%d/%m/%Y") | strftime("%Y%m%d")) catch "Unknown"
          else
            try ($date | strptime("%m/%d/%Y") | strftime("%Y%m%d")) catch "Unknown"
          end
      elif ($raw | test("^[0-9]{1,2}-[0-9]{1,2}-[0-9]{4}")) then
        ($raw | match("^[0-9]{1,2}-[0-9]{1,2}-[0-9]{4}").string) as $date
        | if ($date | split("-")[0] | tonumber) > 12 then
            try ($date | strptime("%d-%m-%Y") | strftime("%Y%m%d")) catch "Unknown"
          else
            try ($date | strptime("%m-%d-%Y") | strftime("%Y%m%d")) catch "Unknown"
          end
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
  | map(select(length > 0))
  | (first // "Unknown") as $raw
  | ($raw | gsub("[^0-9]"; "")) as $digits
  | if ($digits | length) == 10 then
      "(" + $digits[0:3] + ") " + $digits[3:6] + "-" + $digits[6:10]
    elif ($digits | length) == 11 and ($digits | startswith("1")) then
      "(" + $digits[1:4] + ") " + $digits[4:7] + "-" + $digits[7:11]
    else $raw
    end;

.ClinicalDocument.recordTarget.patientRole
| {
    first_name: (.patient.name.given | xmltext | propercase),
    last_name: (.patient.name.family | xmltext | propercase),
    dob: (.patient.birthTime["@value"] | dateparse),
    gender: (
      .patient.administrativeGenderCode["@displayName"]
      // .patient.administrativeGenderCode["@code"]
      | canonical_gender
    ),
    primary_phone: (.telecom | primary_phone)
  }
' "$INPUT_FILE"
