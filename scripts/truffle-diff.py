# Go through all of the contracts in src/ store the paths
# For each corresponding contract in contracts/
# Strip away all of the leading `import` lines for each
# Diff the two files

# NOTE: run from root directory

import os

def get_text_no_import(text):
  lines = text.split("\n")
  first_import_found = False
  last_import_found = False
  curr_line = ""
  prev_line = ""
  start_index = 0
  for i in range(len(lines)):
    l = lines[i]
    curr_line = l
    if curr_line[0:6] == 'import' and prev_line[0:6] != 'import':
      first_import_found = True
    if curr_line[0:6] != 'import' and prev_line[0:6] == 'import':
      last_import_found = True
    if first_import_found and last_import_found:
      start_index = i
      break
    prev_line = curr_line
  # Remove all whitespace
  return ["".join(line.split()) for line in lines[start_index:]]

dir1 = './src/'
dir2 = './contracts/'

def print_diff(filename):
  text1 = None
  text2 = None
  with open(dir1 + filename, 'r') as f:
    text1 = get_text_no_import(f.read())
  with open(dir2 + filename, 'r') as f:
    text2 = get_text_no_import(f.read())
  diffs = (set(text1).difference(text2))
  print(filename)
  for d in diffs:
    diffed_line = d.strip()
    if diffed_line[0:2] != '//' and diffed_line[0:1] != '@':
      print(diffed_line)
  print('------------------------')


for f in os.listdir(dir1):
  if os.path.splitext(f)[1] == '.sol':
    print_diff(f)