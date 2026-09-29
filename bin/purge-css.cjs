const fs = require("node:fs");
const path = require("node:path");
const { PurgeCSS } = require("purgecss");
const config = require("../purgecss.config.js");

async function main() {
  process.chdir(path.resolve(__dirname, ".."));
  const directory = path.resolve(config.output);
  const expected = fs
    .readdirSync(directory)
    .filter((file) => file.endsWith(".css"))
    .map((file) => path.join(directory, file))
    .sort();
  const results = await new PurgeCSS().purge(config);
  const processed = results.map((result) => path.resolve(result.file)).sort();
  if (!expected.length || JSON.stringify(processed) !== JSON.stringify(expected) || results.some((result) => !result.css.trim())) {
    throw new Error("PurgeCSS must process every generated stylesheet and produce nonempty CSS.");
  }

  let before = 0;
  let after = 0;
  for (const result of results) {
    before += fs.statSync(result.file).size;
    after += Buffer.byteLength(result.css);
    fs.writeFileSync(result.file, result.css);
  }
  console.log(`PurgeCSS processed ${results.length} stylesheets: ${before} -> ${after} bytes.`);
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
