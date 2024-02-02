# This script generates a csv file in the current directory containing the list of kubernetes resources that are tagged with security controls.
# It also parses markdown file to extract their security controls information
#
# The following fields are populated in the csv.
# | Security Control | File Type | File Name | Kubernetes Resource Name | Details |

import os
import re
import yaml
import csv

# Create an empty list to store the inventory
inventory = []

# Walk through the current folder and its subfolders
for root, dirs, files in os.walk('.'):
    # Check each file in the current folder
    for file in files:
        ##################
        # YAML FILE
        ##################
        if file.endswith('.yaml'):
            # Open the file for reading
            with open(os.path.join(root, file), 'r') as f:
                # Create an empty string to store the resource
                resource = ''

                # Read the file line by line
                for line in f:
                    # If the line is "---"
                    if line.strip() == '---':
                        # Check for matches of the pattern
                        matches = re.findall(r'(AC-[^,\ \n]+|AU-[^,\ \n]+|IA-[^,\ \n]+|SC-[^,\ \n]+|AT-[^,\ \n]+|CM-[^,\ \n]+|CP-[^,\ \n]+|IR-[^,\ \n]+|MA-[^,\ \n]+|MP-[^,\ \n]+|PS-[^,\ \n]+|SI-[^,\ \n]+|CA-[^,\ \n]+|PL-[^,\ \n]+|RA-[^,\ \n]+|SA-[^,\ \n]+)', resource)
                        # For each match found
                        for match in matches:
                            # Load the YAML data from the resource string
                            data = yaml.safe_load(resource)
                            # Extract the value of the metadata.name node
                            resource_name = data['metadata']['name']
                            # Add an item to the inventory list with the security control(match), file type, file name, resource name and details(resource)
                            inventory.append((match, "kubernetes", os.path.join(root, file), resource_name, resource))
                        # Reset the resource string to empty
                        resource = ''
                    else:
                        # Add the current line to the resource string
                        resource += line

                # Check for matches of the pattern
                matches = re.findall(r'(AU-[^,\ \n]+|AC-[^,\ \n]+|IA-[^,\ \n]+|SC-[^,\ \n]+)', resource)
                # For each match found
                for match in matches:
                    # Load the YAML data from the resource string
                    data = yaml.safe_load(resource)
                    # Extract the value of the metadata.name node
                    resource_name = data['metadata']['name']
                    # Add an item to the inventory list with the security control(match), file type, file name, resource name and details(resource)
                    inventory.append((match, "kubernetes", os.path.join(root, file), resource_name, resource))

        ##################
        # MARKDOWN FILE
        ##################
        if file.endswith('.md'):
            # Open the file for reading
            with open(os.path.join(root, file), 'r') as f:
                content = f.read()
                pattern = r'^(AU-[^\ ]+|AC-[^\ ]+|IA-[^\ ]+|SC-[^\ ]+).*?(\w.*?)(?=\n#|\Z)'
                matches = re.findall(pattern, content, re.DOTALL | re.MULTILINE)
                for match in matches:
                    # Add an item to the inventory list with the security control(match), file type, file name, resource name and details
                    inventory.append((match[0], "markdown", os.path.join(root, file), "---", match[1]))

# Sort the inventory list alphabetically on the match column, filename and resource name
inventory.sort(key=lambda x: (x[0], x[2], x[3]))

# write inventory.csv using "%" as delimiter
with open('inventory.csv', 'w') as file:
    writer = csv.writer(file, delimiter='%')
    writer.writerows(inventory)