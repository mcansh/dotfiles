module.exports = {
  config: {
    // default font size in pixels for all tabs
    fontSize: 13,

    // font family with optional fallbacks
    fontFamily: 'SFMono-Medium',
    uiFontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol"',

    // terminal cursor background color and opacity (hex, rgb, hsl, hsv, hwb or cmyk)
    // cursorColor: 'rgba(248,28,229,0.8)',
    cursorColor: '#EAC72E',

    // `BEAM` for |, `UNDERLINE` for _, `BLOCK` for █
    cursorShape: 'BLOCK',

    // color of the text
    foregroundColor: '#fff',

    // terminal background color
    backgroundColor: '#2b3e50',

    // border color (window, tabs)
    borderColor: 'transparent',

    cursorBlink: false,

    // custom css to embed in the main window
    css: `
      .tabs_nav.nav_1qfk {
        overflow: hidden;
      }

      .tab_tab {
        background: rgba(255,255,255,0.05);
        width: 100%;
        border: none;
      }

      .tab_tab.tab_active {
        background: none;
      }

      .tabs_borderShim.borderShim_nfs {
        border-color: transparent !important;
      }
    `,

    // custom css to embed in the terminal window
    termCSS: `
      x-screen a {
        color: #fee553;
      }
    `,

    // set to `true` if you're using a Linux set up
    // that doesn't shows native menus
    // default: `false` on Linux, `true` on Windows (ignored on macOS)
    showHamburgerMenu: '',

    // set to `false` if you want to hide the minimize, maximize and close buttons
    // additionally, set to `'left'` if you want them on the left, like in Ubuntu
    // default: `true` on windows and Linux (ignored on macOS)
    showWindowControls: '',

    // custom padding (css format, i.e.: `top right bottom left`)
    padding: '5px 14px',

    // the full list. if you're going to provide the full color palette,
    // including the 6 x 6 color cubes and the grayscale map, just provide
    // an array here instead of a color map object
    colors: {
      black: '#2F3D50',
      red: '#B73730',
      green: '#EA9E2C',
      yellow: '#FC8589',
      blue: '#417EB9',
      magenta: '#954EB4',
      cyan: '#85C774',
      white: '#BEC3C7',
      lightBlack: '#2D3B4C',
      lightRed: '#DD4941',
      lightGreen: '#3BA155',
      lightYellow: '#EAC72E',
      lightBlue: '#4F93D8',
      lightMagenta: '#954EB4',
      lightCyan: '#45BD9A',
      lightWhite: '#ffffff'
    },

    // the shell to run when spawning a new session (i.e. /usr/local/bin/fish)
    // if left empty, your system's login shell will be used by default
    shell: '/bin/zsh',

    // for setting shell arguments (i.e. for using interactive shellArgs: ['-i'])
    // by default ['--login'] will be used
    shellArgs: ['--login'],

    // for environment variables
    env: {},

    // set to false for no bell
    bell: 'false',

    // URL to custom bell
    // bellSoundURL: 'http://example.com/bell.mp3',

    // if true, selected text will automatically be copied to the clipboard
    copyOnSelect: false,

    // for advanced config flags please refer to https://hyper.is/#cfg
    windowSize: [650,440],
  },

  // a list of plugins to fetch and install from npm
  // format: [@org/]project[#version]
  // examples:
  //   `hyperpower`
  //   `@company/project`
  //   `project#1.0.1`
  plugins: [
    'hyperterm-close-on-left',
    'hypercwd',
    'hyperterm-alternatescroll',
    'hyperlinks',
    "hyperterm-cobalt2-theme"
    // 'hyperterm-panda',
  ],


  // in development, you can create a directory under
  // `~/.hyper_plugins/local/` and include it here
  // to load it and avoid it being `npm install`ed
  localPlugins: [],

  updateChannel: 'canary'
};
