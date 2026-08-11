import bibtexparser
import tomli_w
import json

def convert(bib_file, toml_file):
    with open(bib_file, 'r', encoding='utf-8') as b:
        parser = bibtexparser.bparser.BibTexParser(common_strings=True)
        parser.ignore_nonstandard_types = False
        parser.homogenize_fields = False
        bib_database = bibtexparser.load(b, parser=parser)
    
    # We want a list of entries or a dict where keys are IDs
    # In TOML, an array of tables is [[entries]]
    # or a dictionary [entries.ID]
    # Let's make it a dict:
    out = {}
    for entry in bib_database.entries:
        key = entry['ID']
        # Remove ID from entry itself if we use it as key
        # entry.pop('ID', None)
        out[key] = entry
    
    with open(toml_file, 'wb') as t:
        tomli_w.dump(out, t)

convert('papers.bib', 'papers.toml')
convert('software.bib', 'software.toml')
