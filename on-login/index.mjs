import { getMacOSVersion, macOSVersions } from "./get-macos-version.mjs"

async function main() {
  const { currentVersion, releaseName } = await getMacOSVersion();
  console.log(`Current macOS version: ${releaseName} (${currentVersion})`);
  if (
    macOSVersions.get("Big Sur") > currentVersion &&
    currentVersion >= macOSVersions.get("Mojave")
  ) {
    const { setRandomColor } = await import("./set-random-color.mjs");
    await setRandomColor();
  }
}

main();
