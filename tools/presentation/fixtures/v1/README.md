# Compiled interface v1 test inputs

Test-only; these files are not loaded by the addon or included in an installable
content package. They contain the already-played opening Balance of Nature example.

Generated without compiler changes using `compile_guide()` and `lua()` from
campaign compiler commit `65becb43d3948e4238b5a576240b394e96a5d26b`.
Source files: `campaign/guide-format/examples/kal01-balance-{route-only,with-narration}/GUIDE.yaml`.
The reviewed compiler files were read from a Git archive into a temporary directory;
the campaign checkout and current source work were not touched.

`guide.txt` is the exact common native payload, SHA-256
`c9e9a0f7d01c8136fc7fd7472cf71e64e8eaf17ca50801c952c9cd847a865c79`.
`route.lua` and `narrated.lua` return literal metadata definitions with the original
compiler/source/schema hashes. Target-viewer revision records the earlier review
baseline; it is provenance, not a compatibility check. These fixtures test addon
staging/binding and native advancement; they do not establish narrative delivery.

`package/Metadata.lua` and `package/Guide.lua` are the unmodified actual compiler
files generated at the same compiler commit against clean viewer `a51a854` for
public-loader regression tests. They use the same played source and native bytes.
Target-viewer SHA remains provenance; binding checks the payload and parsed mapping.
The installable test build is generated separately against the final committed
consumer, rather than relabeling these fixture files as a release.
