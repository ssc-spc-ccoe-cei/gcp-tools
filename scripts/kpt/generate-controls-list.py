import os
import re
import yaml

# Create an empty list to store the inventory
inventory = []

# Walk through the current folder and its subfolders
for root, dirs, files in os.walk('.'):
    # Check each file in the current folder
    for file in files:
        # If the file is a .yaml file
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
                        matches = re.findall(r'(AU-[^,\ \n]+|AC-[^,\ \n]+|IA-[^,\ \n]+|SC-[^,\ \n]+)', resource)
                        # For each match found
                        for match in matches:
                            # Load the YAML data from the resource string
                            data = yaml.safe_load(resource)
                            # Extract the value of the metadata.name node
                            resource_name = data['metadata']['name']
                            # Add an item to the inventory list with the match, file name, resource name and resource
                            inventory.append((match, os.path.join(root, file), resource_name, resource))
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
                    # Add an item to the inventory list with the match, file name, resource name and resource
                    inventory.append((match, os.path.join(root, file), resource_name, resource))

# Sort the inventory list alphabetically on the match column
inventory.sort(key=lambda x: x[0])

# Create a markdown table with the inventory
table = '| Security Control | File Name | Resource Name |\n'
table += '|-------|-----------|---------------|\n'
for item in inventory:
    table += '| {} | {} | {} |\n'.format(*item)

# Open the securitycontrols.md file for reading
with open('securitycontrols.md', 'r') as f:
    content = f.read()

# Define the start and end anchors
start_anchor = '<!-- BEGINNING OF SECURITY CONTROLS LIST -->'
end_anchor = '<!-- END OF SECURITY CONTROLS LIST -->'

# Find the index of the start and end anchors in the content string
start_index = content.index(start_anchor) + len(start_anchor)
end_index = content.index(end_anchor)

# Create a new content string with the table inserted between the start and end anchors
new_content = content[:start_index] + '\n' + table + '\n' + content[end_index:]

# Open the securitycontrols.md file for writing and overwrite its contents with the new content string
with open('securitycontrols.md', 'w') as f:
    f.write(new_content)