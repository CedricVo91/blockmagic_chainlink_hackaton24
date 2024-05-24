import json

with open("MockDaiTokenv3.json", "r") as file:
    mockDAI_json = json.load(file)

def print_keys(d, indent=0):
    if isinstance(d, dict):
        for key, value in d.items():
            print("    " * indent + str(key))
            print_keys(value, indent + 1)
    elif isinstance(d, list):
        for item in d:
            print_keys(item, indent + 1)

print_keys(mockDAI_json)