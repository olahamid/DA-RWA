<!-- PROJECT SHIELDS -->

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <h3 align="center">DA-RWA Tokenization Platform</h3>

  <p align="center">
    A modular platform for tokenizing real-world assets (RWA) using ERC1155
    <br />
    <a href="https://github.com/olahamid/OA-RWA/issues/new/choose">Report Bug</a>
    ·
    <a href="https://github.com/olahamid/OA-RWA/issues/new/choose">Request Feature</a>
  </p>
</div>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#architecture">Architecture</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
  </ol>
</details>

<!-- ABOUT THE PROJECT -->
## About The Project

The DA-RWA Tokenization Platform is a flexible infrastructure that enables various RWA platforms to tokenize real-world assets. Using ERC1155, it supports both unique asset representation (NFTs) and fractionalized ownership tokens, making it suitable for a wide range of assets from luxury watches to real estate,vehicles, gold, daimonds, etc. making it possible for all real-world asset to be tokenised on the blockchain.

### Built With

- Solidity
- OpenZeppelin
- Foundry
- Chainlink or LayerZero(planned for cross-chain functionality)

<!-- GETTING STARTED -->
## Getting Started

### Prerequisites

- Foundry
- Git

### Installation

1. Clone the repository
```shell
https://github.com/olahamid/OA-RWA.git
```

2. Install NPM packages
```shell
forge install
```
3. Run Build
```shell
forge build --via-ir
```
4. Run tests
```shell
forge test
```

## Architecture

The platform consists of several key components:

1. Registry System

2. Asset Creation (ERC1155)

3. Function Sources
  
4. Cross chain functionality(TBC) 

<!-- ROADMAP -->
## Roadmap

- [x] SMART CONTRACT DEVELOPMENT
- [ ] UNIT/INTEGRATION TEST DEVELOPMENT
- [ ] SCRIPT DEVELOPMENT

See the [open issues](https://github.com/olahamid/OA-RWA/issues) for a full list of proposed features and known issues.

<!-- CONTRIBUTING -->
## Contributing

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/YourBranch`)
3. Commit your Changes (`git commit -m 'Add some cool Changes'`)
4. Push to the Branch (`git push origin feature/YourBranch`)
5. Open a Pull Request

<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<!-- CONTACT -->
## Contact

OLA HAMID - [@telegram](https://t.me/Ola_Hamid)

Project Link: [https://github.com/olahamid/OA-RWA](https://github.com/olahamid/OA-RWA)

<!-- MARKDOWN LINKS & IMAGES -->
[contributors-shield]: https://img.shields.io/github/contributors/olahamid/OA-RWA.svg?style=for-the-badge
[contributors-url]: https://github.com/olahamid/OA-RWA/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/olahamid/OA-RWA.svg?style=for-the-badge
[forks-url]: https://github.com/olahamid/OA-RWA/network/members
[stars-shield]: https://img.shields.io/github/stars/olahamid/OA-RWA.svg?style=for-the-badge
[stars-url]: https://github.com/olahamid/OA-RWA/stargazers
[issues-shield]: https://img.shields.io/github/issues/olahamid/OA-RWA.svg?style=for-the-badge
[issues-url]: https://github.com/olahamid/OA-RWA/issues
[license-shield]: https://img.shields.io/github/license/olahamid/OA-RWA.svg?style=for-the-badge
[license-url]: https://github.com/olahamid/OA-RWA/blob/main/LICENSE