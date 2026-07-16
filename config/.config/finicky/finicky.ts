import type { FinickyConfig } from "/Applications/Finicky.app/Contents/Resources/finicky.d.ts";

export default {
  defaultBrowser: "Safari",
  options: {
    logRequests: false,
    checkForUpdates: false,
    hideIcon: true,
    keepRunning: true,
  },
  rewrite: [
    // Replace domain of urls to amazon.com with smile.amazon.com
    {
      match: finicky.matchHostnames(["www.amazon.com", "amazon.com"]),
      url(url) {
        url.host = "smile.amazon.com";
        return url;
      },
    },
    {
      match: finicky.matchHostnames(["int.www.uwm.com"]),
      url(url) {
        url.host = "www.int.uwm.com";
        return url;
      },
    }
  ],
  handlers: [
    {
      // generic
      match: [
        createRegex("stackblitz.com"),
        createRegex("vite.new"),
        createRegex("meet.google"),
      ],
      browser: "Brave Browser Nightly",
    },

    // shopify
    {
      match(url) {
        let matches = [
          "https://github.com/shopify",
          "https://workplace.com/shopify",
        ];
        return matches.some((match) => url.href.startsWith(match));
      },
      browser: "Brave Browser Nightly",
    },

    // uwm
    {
      match(url, { opener }) {
        let hosts = ["uwm.com", "uwm.csod.com", "url.us.m.mimecastprotect.com", "code.uwm.com"];
        return (
          opener?.bundleId === "com.microsoft.teams2" ||
          hosts.includes(url.host)
        )
      },
      browser: {
        appType: "path",
        name: "/Applications/Brave Browser Nightly.app"
      }
    },
  ],
} satisfies FinickyConfig;

/** create a regex that matches any subdomain of the given domain, including the domain itself, and any path*/
function createRegex(domain: string, { subdomains, paths }: {
  subdomains?: string[];
  paths?: string[];
} = {}) {
  subdomains ??= [];
  paths ??= [];

  // if no subdomains are provided, match any subdomain
  if (subdomains.length === 0) {
    subdomains = ["(?:[^.]+\\.)*"];
  } else {
    subdomains = subdomains.map((subdomain) => `${subdomain}\\.`);
  }

  // if no paths are provided, match any path
  if (paths.length === 0) {
    paths = ["(?:/.*)?"];
  } else {
    paths = paths.map((path) => `${path}`);
  }

  return new RegExp(
    `^https?://${subdomains.join("")}${domain}${paths.join("|")}$`,
  );
}
