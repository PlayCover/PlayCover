<div id="top"></div>

‎<h1 align="center">[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![GPLv3 License][license-shield]][license-url]
[![Weblate](https://img.shields.io/weblate/progress/playcover?style=for-the-badge)](https://hosted.weblate.org/projects/playcover/playcover/)
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
    <a href="https://playcover.github.io/PlayBook">Documentation</a>
    ·
    <a href="https://discord.gg/rMv5qxGTGC">Discord</a>
    ·
    <a href="https://playcover.io/">Website</a>
  </p>
</div>

<!-- ABOUT THE PROJECT -->
## About The Project

Welcome to PlayCover! This software is all about allowing you to run iOS apps and games on Apple Silicon devices running macOS 12.0 or newer.

PlayCover works by putting applications through a wrapper which imitates an iPad. This allows the apps to run natively and perform very well.

PlayCover also allows you to map custom touch controls to keyboard, which is not possible in alternative sideloading methods such as Sideloadly. 

These controls include all the essentials, from WASD, camera movement, left and right clicks, and individual keymapping, similar to a popular Android emulator’s keymapping system called Bluestacks.

This software was originally designed to run Genshin Impact on your Apple Silicon device, but it can now run a wide range of applications. Unfortunately, not all games are supported, and some may have bugs.

Localisations handled in [Weblate](https://hosted.weblate.org/projects/playcover/).

![Fancy logo](./images/dark.png#gh-dark-mode-only)
![Fancy logo](./images/light.png#gh-light-mode-only)

<p align="right"><a href="#top">⬆️ Back to top️</a></p>

<!-- GETTING STARTED -->
## Getting Started

Follow the instructions below to get Genshin Impact, and many other games, up and running in no time.

### Prerequisites

At the moment, PlayCover can only run on Apple Silicon Macs. Devices with the following chips are supported:

* M1
* M1 Pro
* M1 Max
* M1 Ultra
* M2

If you have an Intel Mac, you can explore alternatives like Bootcamp or emulators.

### Download

You can download stable releases [here](https://github.com/PlayCover/PlayCover/releases), or build from source by following the instructions in the Documentation.

### Documentation

To learn how to setup and use PlayCover, visit the documentation [here](https://playcover.github.io/PlayBook).

### Homebrew Cask
We host a [Homebrew](https://brew.sh) tap with the [PlayCover cask](https://github.com/PlayCover/homebrew-playcover/blob/master/Casks/playcover-community.rb). To install from it:

1. Tap `PlayCover/playcover` with `brew tap PlayCover/playcover`;
2. Install PlayCover with `brew install --cask playcover-community`.

To uninstall:
1. Remove PlayCover using `brew uninstall --cask playcover-community`;
2. Untap `PlayCover/playcover` with `brew untap PlayCover/playcover`.

<p align="right"><a href="#top">⬆️ Back to top️</a></p>



<!-- LICENSE -->
## License

Distributed under the GPLv3 License. See `LICENSE` for more information.

### Disclaimer

- This fork has been created by the community to support the development of PlayCover, since the original project became non-free and non-open-source.
- This fork is not affiliated with the original project, nor the original author.
- This fork is not affiliated with the website <https://playcover.me>.
- If you have any questions, please ask the community for help first.
- The original project is under GNU General Public License v3.0, so there is no legal issue to fork it and redistribute.

If anyone feels like this fork somehow violates the copyright (e.g., the logo), please open an issue.

Many things are under construction, so please be patient. Any contribution is welcome.

This fork will always stay open-source and maintained by the community.

<p align="right"><a href="#top">⬆️ Back to top️</a></p>



<!-- CONTACT -->
## Contact

Lucas Lee - playcover@lucas.icu

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
