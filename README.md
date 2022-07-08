<div id="top"></div>

<h1 align="center">[![Contributors][contributors-shield]][contributors-url]
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
    Run iOS apps & games on M1 Mac with mouse, keyboard and controller support.
    <br />
    <br />
    <a href="https://www.youtube.com/watch?v=grY63FBJ6N4">Showcase</a>
    ·
    <a href="https://github.com/PlayCover/PlayCover/pulls">Contribute</a>
    ·
    <a href="https://discord.gg/rMv5qxGTGC">Discord</a>
  </p>
</div>

## About the fork & Disclaimer

This fork have been created by the community to support the development of PlayCover, since the original project became non-free and non-open-source.

This fork is not affiliated with the original project, nor the original author.

This fork is not affiliated with the website <https://playcover.me>.

I am supporting this project in my spare time, so if you have any questions, please ask the community for help first.

The original project is under GNU General Public License v3.0, so there is no legal issue to fork it and redistribute.

Many things are under construction, so please be patient. Any contribution is welcome.

If you want to compile it on your own computer, you may need to make a few changes to the source code:

- Linking paths to the correct libraries
- Auth0 integration
- i18n resources

CI and compilation fixes are comming soon.

If anyone feels like this fork somehow violates the copyright (e.g., the logo), please open an issue.

<!-- ABOUT THE PROJECT -->
## About The Project

Welcome to PlayCover! This software is all about allowing you to run apps & games on your M1 device runnnig macOS 12.0 or newer. 

It does this by putting the applications through a wrapper which imitates an iPad. This allows the apps to perform very well and run natively, because the M1 chip is essentially a glorified mobile chip. Another advantage to the software is that you can insert and manipulate custom controls with your keyboard, which is not possible in alternative sideloading methods such as Sideloadly. These controls include all the essentials, from WASD, Camera movement, Left and Right clicks, and individual keymapping, similar to a popular Android emulator’s keymapping system called Bluestacks. 

While this software was originally created to allow you to run Genshin Impact on your M1 device, it grew to allow many more applications to run. Although support for all games is not promised and bugs with games are expected.

![Fancy logo](./images/dark.png#gh-dark-mode-only)
![Fancy logo](./images/light.png#gh-light-mode-only)

<p align="right"><a href="#top">⬆️ Back to top️</a></p>




<!-- GETTING STARTED -->
## Getting Started

Following the installation instructions will get Genshin Impact you up and running in no time. The steps can be repeated if you want to try out other games or apps.

### Prerequisites

At the moment, PlayCover can only be installed and executed on M1 MacBooks. Devices with the following chips are supported:

* M1
* M1 Pro
* M1 Max
* M1 Ultra

 Unfortunately, it cannot run on any Intel chips, so you are forced to use Bootcamp or other emulators.

### Installation

1. Disable SIP
    - This can be done by shutting down your mac, holding down power button
    - After this, click on your username/ssd, then keep going until you can see `Utilities` at the top
    - When you see this, click on it and click on `Terminal`
    - After this, you should be in a terminal window
    - Type `csrutil disable` in that terminal window
    - Put your password and everything, then restart your mac
    
2. Modify nvram boot-args
    - When you have SIP disabled, type the following: 
        - `Command + Space`, type `Terminal` in the search box
    - It should open a normal terminal window
    - Type the following in this window (or copy paste it)
        - `sudo nvram boot-args="amfi_get_out_of_my_way=1"`
    - If it appears that nothing has happened, this is correct.
    - Now restart your mac once again

3. Login to Genshin
    - Open Genshin Impact with PlayCover, and you should be greeted with a Login button
    - Login to your account, then wait until the door appears and quit the game with `Command + Q`
    - Thats all which is required in Genshin for now

4. Enable SIP
    - Shut down your mac again
    - Hold down the power button until you get to recovery options
    - Click on your username and your storage disk respectively like you did for step 1.
    - You should see `Utilities` at the top
    - Click on it, and Click on `Terminal`
    - In terminal, type the following: `csrutil enable`
        - `csrutil clear` should also work
    - Reboot your mac by going to `Apple Logo` > `Restart`

5. Open Genshin
    - You're done! Enjoy playing genshin!

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

Distributed under the AGPLv3 License. See `LICENSE` for more information.

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