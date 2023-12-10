## Instructions

Script supports Linux only but you can run it on windows/macos and copy resultant `chrome` folder and `user.js` file to Firefox profile path.

1. Install [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) and [npm](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm)
2. Run this command to install

```bash
git clone https://github.com/bbhtt/edge-firefox-minified.git && cd edge-firefox-minified && chmod +x install.sh && ./install.sh
```

3. To update

```bash
./install.sh
```

4. To uninstall, go to Firefox profile folder and delete `chrome` folder, `user.js` file. Then go to `about:config` and reset the prefs set in `user.js` to default values.
