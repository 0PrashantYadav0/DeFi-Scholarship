# DeFi-Scholarship

**DeFi-Scholarship** is a decentralized platform for managing scholarships, utilizing blockchain technology for secure and transparent transactions. Built on the Aptos blockchain, it integrates smart contracts, a chatbot powered by Langchain and Mistral, and a React-based frontend for seamless user interaction.

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Installation](#installation)
- [Usage](#usage)
- [Smart Contracts](#smart-contracts)
- [Chatbot Integration](#chatbot-integration)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

## Introduction

The **DeFi-Scholarship** platform offers a decentralized, transparent, and efficient way to manage scholarships, ensuring that all transactions are verifiable on the Aptos blockchain. With no intermediaries involved, scholarships are disbursed automatically based on predefined criteria through smart contracts written in Move.

### Key Objectives:
- Decentralized scholarship fund management.
- Transparent and verifiable scholarship transactions.
- Automated disbursement processes, reducing administrative overhead.
  
## Features

- **React-Based Frontend**: An intuitive user interface built with React for applying, managing, and reviewing scholarships.
- **Move Smart Contracts**: Scholarship fund distribution is managed by secure and efficient smart contracts on the Aptos blockchain.
- **Blockchain Transparency**: Every transaction is recorded on the Aptos blockchain, ensuring verifiability.
- **Chatbot Assistance**: Integrated chatbot using Langchain and Mistral to assist users with the application process and inquiries.
- **Secure File Storage**: Applicant documents are securely stored and accessed using decentralized storage.

## Technology Stack

- **Frontend**: React.js
- **Blockchain**: Aptos blockchain for decentralized ledger management.
- **Smart Contracts**: Written in Move for secure and efficient execution.
- **Chatbot**: Powered by Langchain and Mistral for user assistance.
- **Backend**: Node.js for API development.
- **Web3 Integration**: Interaction with the Aptos blockchain using Web3.js and Aptos libraries.

## Installation

To set up the project locally, follow these steps:

1. Clone the repository:
   ```bash
   git clone https://github.com/0PrashantYadav0/DeFi-Scholarship.git
   ```

2. Navigate to the project directory:
   ```bash
   cd DeFi-Scholarship
   ```

3. Install the required dependencies for the frontend and backend:
   ```bash
   npm install
   ```

4. Deploy the Move smart contracts (using Aptos):
   - Update the contract configuration in the aptos-config.json file.
   - Compile and deploy:
     ```bash
     aptos move compile
     aptos move publish
     ```

5. Start the application:
   ```bash
   npm start
   ```

## Usage

Once the system is up and running:

1. **Apply for Scholarships**: Users can submit their applications through the React-based frontend.
2. **Manage Applications**: Scholarship administrators can review applications and approve or reject them.
3. **Chatbot Assistance**: Users can interact with the integrated chatbot for help during the application process.
4. **Disbursement**: Scholarship funds are automatically disbursed through the Move smart contracts.
5. **Transaction Verification**: All scholarship-related transactions are recorded on the Aptos blockchain.

## Smart Contracts

The Move smart contracts are the backbone of DeFi-Scholarship, automating the entire scholarship process, from application to disbursement.

- **Scholarship Contract**: Manages the entire scholarship lifecycle, including application submission, review, and fund distribution.
- **Eligibility Contract**: Ensures only eligible applicants receive scholarships based on pre-configured rules.

## Chatbot Integration

A Langchain and Mistral powered chatbot is integrated into the platform, providing assistance with:

- Guiding users through the scholarship application process.
- Answering questions about eligibility and fund disbursement.
- Offering personalized suggestions based on user input.

## Contributing

We welcome contributions to enhance DeFi-Scholarship. To contribute:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature-branch`).
3. Make your changes.
4. Submit a pull request with a detailed description.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.

## Contact

For any inquiries or support, please contact @NeonKazuha and @0PrashantYadav0.