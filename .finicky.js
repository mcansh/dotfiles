// Generated by Finicky Kickstart
// Save as ~/.finicky.js

module.exports = {
  defaultBrowser: "Safari",
  options: {
    hideIcon: true,
  },
  rewrite: [
    // Replace domain of urls to amazon.com with smile.amazon.com
    {
      match: finicky.matchDomains(["www.amazon.com", "amazon.com"]),
      url: ({ urlString }) => {
        return { ...url, host: "smile.amazon.com" };
      },
    },
  ],
  handlers: [
    {
      match: /^https:\/\/stackblitz\.com\/.*$/,
      browser: "Google Chrome Canary",
    },
    {
      match: /^https:\/\/vite\.new\/.*$/,
      browser: "Google Chrome Canary",
    },
    {
      match: /^https:\/\/meet.google.com\/.*$/,
      browser: "Google Chrome Canary",
    },
  ],
};
