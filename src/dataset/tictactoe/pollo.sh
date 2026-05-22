#!/bin/bash

# Check if input file is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 input_file"
    exit 1
fi

input_file=$1
output_file="formatted_${input_file}"

# Process the file:
# Accumulate characters and add comma between them
# When "positive" or "negative" is found, print the line
awk '
    BEGIN { 
        line = ""
    }
    /^(positive|negative)$/ { 
        print line "," $0
        line = ""
        next
    }
    {
        if (NF > 0) {
            if (line == "") {
                line = $0
            } else {
                line = line "," $0
            }
        }
    }
' "$input_file" > "$output_file"

echo "Formatting complete. Output saved to $output_file"