# Narration fixture — played opening example

`Metadata.lua` and `Guide.lua` are unmodified compiler output for the small,
already-played Guide Format v1 example:

```sh
python3 tools/content/compile_v1.py \
  --guide campaign/guide-format/examples/kal01-balance-with-narration/GUIDE.yaml \
  --output /tmp/v1-fixture \
  --fork /path/to/clean/pinned-viewer
```

Generated from campaign `main` at `224a2dc2fe2c5079cc0b052036d6e36e65eb89c5`
(compiler 0.2.0). The recorded viewer provenance is
`840376de42057863cacd1cb2f776898fcc50d131`.

This fixture contains only the played Shadowglen example. Do not replace it with
private future-chapter prose. The metadata sidecar is optional; `Guide.lua` is
ordinary native Zygor content and must register even when no consumer exists.