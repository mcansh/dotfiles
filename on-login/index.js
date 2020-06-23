const { getMacOSVersion, macOSVersions } = require("./get-macos-version");

async function main() {
  const { currentVersion } = await getMacOSVersion();
  if (
    macOSVersions["Big Sur"] > currentVersion &&
    currentVersion >= macOSVersions["Mojave"]
  ) {
    require("./set-random-color");
  }
}

main();
