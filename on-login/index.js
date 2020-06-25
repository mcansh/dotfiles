const { getMacOSVersion, macOSVersions } = require("./get-macos-version");

async function main() {
  const { currentVersion } = await getMacOSVersion();
  if (
    macOSVersions["Big Sur"] > currentVersion &&
    currentVersion >= macOSVersions["Mojave"]
  ) {
    const { setRandomColor } = require("./set-random-color");
    await setRandomColor();
  }
}

main();
