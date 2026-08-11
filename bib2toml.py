import sys
import re

def parse_bib(filename):
    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()

    entries = []
    # simple bibtex regex
    # finds @TYPE{KEY, ...}
    for match in re.finditer(r'@(\w+)\s*\{\s*([^,]+),', content):
        entry_type = match.group(1).lower()
        key = match.group(2)
        start = match.end()
        # Find matching closing brace
        depth = 1
        for i in range(start, len(content)):
            if content[i] == '{':
                depth += 1
            elif content[i] == '}':
                depth -= 1
                if depth == 0:
                    end = i
                    break
        else:
            continue
            
        body = content[start:end]
        
        fields = {}
        # Parse fields: key = value
        # This is a basic parser. It handles nested braces roughly.
        field_matches = re.finditer(r'([a-zA-Z0-9_]+)\s*=\s*(.*)', body)
        # Actually it's easier to process line by line or split by comma?
        # But values can contain commas.
        pass

