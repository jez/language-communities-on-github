# Takes an array of objects (all of whom have the same properties)
# and outputs CSV, with a row for each object, and no header.
# Use this line for header information:
#    $cols, $rows[] |
(map(keys) | add | unique) as $cols |
  map(. as $row | $cols | map($row[.])) as $rows |
  $rows[] |
  @csv

