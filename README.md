<div id="top"></div>

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![MIT License][license-shield]][license-url]
[![Discord][discord-shield]][discord-url]
[![Translated][translated-shield]][translated-url]

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
    <a href="https://docs.playcover.io">Documentation</a>
    ·
    <a href="https://hosted.weblate.org/projects/playcover">Localisation</a>
    ·
    <a href="https://discord.gg/RNCHsQHr3S">Discord</a>
    ·
    <a href="https://playcover.io/">Website</a>
  </p>
</div>

<!-- ABOUT THE PROJECT -->

## About The Project

PlayCover is all about allowing you to run iOS apps and games on Apple Silicon devices running macOS 12.0 or newer. It works by putting applications through a wrapper which imitates an iPhone/iPad. This allows the apps to run natively and perform very well. It also allows you to map custom touch controls to keyboard, which is not possible in alternative sideloading methods such as Sideloadly. These controls include all the essentials, from WASD, camera movement, left and right clicks, and individual keymapping, similar to a popular Android emulator’s keymapping system called Bluestacks.

Unfortunately, not all apps and games are supported, and some may have bugs.

![Fancy logo](./images/dark.png#gh-dark-mode-only)
![Fancy logo](./images/light.png#gh-light-mode-only)

<!-- GETTING STARTED -->

## Getting Started

<!-- This is a quick start guide to using PlayCover.

A more detailed guide can be found on our [docs](https://docs.playcover.io) -->

### Prerequisites

At the moment, PlayCover can only run on Apple Silicon Macs. Devices with the following chips are supported:

-   M1
-   M1 Pro
-   M1 Max
-   M1 Ultra
-   M2

If you have an Intel Mac, you can explore alternatives like Bootcamp or android emulators.

### Download

-   #### Github

    You can download stable releases [here](https://github.com/PlayCover/PlayCover/releases)

-   #### HomeBrew

    We host a [Homebrew](https://brew.sh) tap with the [PlayCover cask](https://github.com/PlayCover/homebrew-playcover/blob/master/Casks/playcover-community.rb). To install from it:

        1. Tap `PlayCover/playcover` with `brew tap PlayCover/playcover`.
        2. Install PlayCover with `brew install --cask playcover-community`.

<!--
To uninstall:
3. Remove PlayCover using `brew uninstall --cask playcover-community`;
4. Untap `PlayCover/playcover` with `brew untap PlayCover/playcover`. -->

### Installation

You can download stable releases [here](https://github.com/PlayCover/PlayCover/releases), or build from source by following the instructions in the Documentation.

<!-- USAGE EXAMPLES -->

<!-- ## Usage

Use this space to show useful examples of how a project can be used. Additional screenshots, code examples and demos work well in this space. You may also link to more resources.

_For more examples, please refer to the [Documentation](https://example.com)_ -->

<!-- CONTRIBUTING -->

## Contributing

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement". This project is fueled by the community, any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<!-- CONTACT -->

## Contact

All formal inqueries are done via [email](mailto:contact@playcover.io).

Any informal inqueries can be done via our [Discord](https://discord.gg/RNCHsQHr3S) or [Twitter](https://twitter.com/playcoverapp).

<!-- ACKNOWLEDGMENTS -->

## Libraries Used

These open source libraries were used to create this project.

-   [Yams](https://github.com/jpsim/Yams)
-   [inject](https://github.com/paradiseduo/inject)
-   [Sparkle](https://github.com/sparkle-project/Sparkle)
-   [Carthage](https://github.com/Carthage/Carthage)
-   [PlayTools](https://github.com/PlayCover/PlayTools)
-   [DataCache](https://github.com/huynguyencong/DataCache)
-   [DownloadManager](https://github.com/shapedbyiris/download-manager)
-   [SwiftUI CachedAsyncImage](https://github.com/lorenzofiamingo/swiftui-cached-async-image)

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
[translated-shield]: https://img.shields.io/weblate/progress/playcover?style=for-the-badge
[translated-url]: https://hosted.weblate.org/projects/playcover/playcover
[discord-shield]: https://img.shields.io/discord/871829896492642387?logo=Discord&style=for-the-badge
[discord-url]: https://discord.gg/RNCHsQHr3S
