<div id="top"></div>

‎<h1 align="center">[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![GPLv3 License][license-shield]][license-url]
</h1>



<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/PlayCover/PlayCover">
    <img src="images/logo.png" alt="Logo" width="80" height="80">
  </a>

  <h3 align="center">PlayCover</h3>

  <p align="center">
    Run iOS apps and games on Apple Silicon Macs with mouse, keyboard and controller support.
    <br />
    <br />
    <a href="https://www.youtube.com/watch?v=grY63FBJ6N4">Showcase</a>
    ·
    <a href="https://github.com/PlayCover/PlayCover/pulls">Contribute</a>
    ·
    <a href="https://discord.gg/rMv5qxGTGC">Discord</a>
  </p>
</div>

## Disclaimer

- This fork has been created by the community to support the development of PlayCover, since the original project became non-free and non-open-source.
- This fork is not affiliated with the original project, nor the original author.
- This fork is not affiliated with the website <https://playcover.me>.
- If you have any questions, please ask the community for help first.
- The original project is under GNU General Public License v3.0, so there is no legal issue to fork it and redistribute.

If anyone feels like this fork somehow violates the copyright (e.g., the logo), please open an issue.

Many things are under construction, so please be patient. Any contribution is welcome.

This fork will always stay open-source and maintained by the community.

<!-- ABOUT THE PROJECT -->
## About The Project

Welcome to PlayCover! This software is all about allowing you to run iOS apps and games on Apple Silicon devices running macOS 12.0 or newer.

PlayCover works by putting applications through a wrapper which imitates an iPad. This allows the apps to run natively and perform very well.

PlayCover also allows you to map custom touch controls to keyboard, which is not possible in alternative sideloading methods such as Sideloadly. 

These controls include all the essentials, from WASD, camera movement, left and right clicks, and individual keymapping, similar to a popular Android emulator’s keymapping system called Bluestacks.

This software was originally designed to run Genshin Impact on your Apple Silicon device, but it can now run a wide range of applications. Unfortunatley, not all games are supported, and some may have bugs.

![Fancy logo](./images/dark.png#gh-dark-mode-only)
![Fancy logo](./images/light.png#gh-light-mode-only)

<p align="right"><a href="#top">⬆️ Back to top️</a></p>

<!-- GETTING STARTED -->
## Getting Started

Following the instructions below to get Genshin Impact, and many other games, up and running in no time.

### Prerequisites

At the moment, PlayCover can only run on Apple Silicon Macs. Devices with the following chips are supported:

* M1
* M1 Pro
* M1 Max
* M1 Ultra
* M2

If you have an Intel Mac, you can explore alternatives like Bootcamp or emulators.

### Download

You can download finished releases [here](https://github.com/PlayCover/PlayCover/releases), or build from source by following the instructions below.

### Homebrew Cask
We host a [Homebrew](https://brew.sh) tap with the [PlayCover cask](https://github.com/PlayCover/homebrew-playcover/blob/master/Casks/playcover-community.rb). To install from it:

1. Tap `PlayCover/playcover` with `brew tap PlayCover/playcover`;
2. Install PlayCover with `brew install --cask playcover-community`.

To uninstall:
1. Remove PlayCover using `brew uninstall --cask playcover-community`;
2. Untap `PlayCover/playcover` with `brew untap PlayCover/playcover`.


### Build from Source

You will need:

- [Carthage](https://formulae.brew.sh/formula/carthage)
- Xcode
- An Apple ID

Clone this repo, and open it in Xcode. You have to codesign it with your Apple ID in Xcode. You can do this by going to `Navigator > PlayCover > Signing & Capabilities` and setting the `Provising Profile` to None, and setting the `Team` to your personal Apple ID team.

### Extra Installation Steps For Genshin Impact

1. Disable SIP
    - First shut down your Mac completely so the screen is black and all other lights are off
    - Press and hold the power button on your Mac until `Loading startup options` appears
    - Select `Options` and continue
    - If prompted, select the correct storage disk
    - Log in with your administrator account 
    - When `Utilities` appears in the menu bar, click on it and choose `Terminal`
    - In the terminal window type `csrutil disable` and type your password when prompted
    - Once `Successfully disabled System Integrity Protection` appears, restart your Mac

2. Modify `nvram boot-args`
    - When you have SIP disabled, type the following:
        - `Command + Space`, type `Terminal` in the search box
    - Type or copy the following command in the terminal window that appears
        - `sudo nvram boot-args="amfi_get_out_of_my_way=1"`
    - If it appears that nothing has happened, this is correct.
    - Restart your Mac

3. Login to Genshin
    - Open Genshin Impact with PlayCover, and you should be greeted with a Login button
    - Login to your account, then wait until the door appears and quit the game with `Command + Q`. **DO NOT CLICK/ENTER THE DOOR.**

4. Enable SIP
    - Follow the steps in Step 1 to re-enter startup options
    - When `Utilities` appears in the menu bar, click on it and choose `Terminal`
    - In the terminal window type `csrutil enable` and type your passowrd when prompted
    - Once `Successfully enabled System Integrity Protection` appears, restart your Mac

5. Open Genshin
    - You're done! Enjoy playing Genshin!

### Video Instructions

The above steps are shown in the following video:

[How to play Genshin Impact using Playcover on your M1 Mac (2020 or newer)!](https://www.youtube.com/watch?v=ZRmCjkS3UZE)

<p align="right"><a href="#top">⬆️ Back to top️</a></p>


<!-- USAGE EXAMPLES -->
## Keymapping

### Button Events

* Opens a menu to add a button element
    * Clicking on the screen
* Edit keymapping binding
    * Click on a keymap and press the key you want binded
* Bind left mouse button
    * Clicking on **'LB'**
* Bind right mouse button
    * Clicking on **'RB'**
* Bind middle mouse button
    * Clicking on **'🖱️'**
* Adds a W/A/S/D joystick
    * Clicking on the **'➕'**
* Adds a mouse area for mouse control
    * Clicking on the **'🔁'**

### Flow Control

* Increase the selected buttons size
    * Menu Bar > `Keymapping` > Upsize Selected Element OR `Cmd + '↑'`
* Decrease the selected buttons size
    * Menu Bar > `Keymapping` > Upsize Selected Element OR `Cmd + '↓'`
* Delete the selected keymapping
    * CMD + delete (backspace)
* Toggle between show/hide cursor
    * Press option (⌥)

### Importing Keybinds

1. Download the `.playmap` file from [#📝・keymap-showcase](https://discord.com/channels/871829896492642387/922068254569160745)

2. Open PlayCover and right click the app you wish to import the keybinds to

3. Click on `Import Keymapping`

4. Select the previously downloaded `.playmap` file

5. Quit and reopen the app
    - This step is required for the newly imported keymapping to work

_For additional help, please join the [Discord server](https://discord.gg/rMv5qxGTGC)_

<p align="right"><a href="#top">⬆️ Back to top️</a></p>




<!-- CONTRIBUTING -->
## Contributing

If you have a suggestion that would make this better, please fork the repo and create a pull request. Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<p align="right"><a href="#top">⬆️ Back to top️</a></p>



<!-- LICENSE -->
## License

Distributed under the GPLv3 License. See `LICENSE` for more information.

<p align="right"><a href="#top">⬆️ Back to top️</a></p>



<!-- CONTACT -->
## Contact

Lucas Lee - playcover@lucas.icu

Project Link: [https://github.com/PlayCover/PlayCover](https://github.com/PlayCover/PlayCover)

<p align="right"><a href="#top">⬆️ Back to top️</a></p>



<!-- ACKNOWLEDGMENTS -->
## Libraries Used

These open source libraries were used to create this project.

* [appdecrypt](https://github.com/paradiseduo/appdecrypt/tree/main/Sources/appdecrypt)
* [optool](https://github.com/alexzielenski/optool)
* [PTFakeTouch](https://github.com/Ret70/PTFakeTouch)

* Thanks to @iVoider for creating such a great project!

<p align="right"><a href="#top">⬆️ Back to top️</a></p>



<!-- MARKDOWN LINKS & IMAGES -->
[contributors-shield]: https://img.shields.io/github/contributors/PlayCover/PlayCover.svg?style=for-the-badge
[contributors-url]: https://github.com/PlayCover/PlayCover/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/PlayCover/PlayCover.svg?style=for-the-badge
[forks-url]: https://github.com/PlayCover/PlayCover/network/members
[stars-shield]: https://img.shields.io/github/stars/PlayCover/PlayCover.svg?style=for-the-badge
[stars-url]: https://github.com/PlayCover/PlayCover/stargazers
[issues-shield]: https://img.shields.io/github/issues/PlayCover/PlayCover.svg?style=for-the-badge
[issues-url]: https://github.com/PlayCover/PlayCover/issues
[license-shield]: https://img.shields.io/github/license/PlayCover/PlayCover.svg?style=for-the-badge
[license-url]: https://github.com/PlayCover/PlayCover/blob/master/LICENSE
