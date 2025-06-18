# Bonus Payout Application

A shell script-based application for paying out bonuses using Coinbase through MeshConnect's API. This application allows you to process individual or batch cryptocurrency bonus payments with a user-friendly command-line interface.

## Features

- 🔐 **Secure API Configuration** - Store MeshConnect API credentials securely
- 💰 **Single Bonus Payouts** - Process individual bonus payments interactively
- 📊 **Batch Processing** - Process multiple payouts from CSV files
- 💳 **Multi-Currency Support** - Support for USDC, USDT, ETH, BTC, and more
- 🌐 **Multi-Network Support** - Ethereum, Polygon, BSC, and other networks
- 📝 **Comprehensive Logging** - Track all transactions and system events
- ✅ **Input Validation** - Validate email addresses, wallet addresses, and amounts
- 🔍 **Transaction History** - View and search payout history
- 🧪 **Sandbox Support** - Test in sandbox environment before production

## Requirements

- macOS or Linux system
- Bash 4.0 or higher
- curl (for API requests)
- jq (for JSON parsing - will be installed automatically if using Homebrew)
- MeshConnect API account

## Installation

1. **Clone or download the application:**
   ```bash
   git clone <repository-url> bonus-payout-app
   cd bonus-payout-app
   ```

2. **Make the main script executable:**
   ```bash
   chmod +x bonus-payout.sh
   ```

3. **Run the application:**
   ```bash
   ./bonus-payout.sh
   ```

## Setup

### 1. Get MeshConnect API Credentials

1. Sign up for a MeshConnect account at [meshconnect.com](https://meshconnect.com)
2. Complete the KYB (Know Your Business) process for production access
3. Generate API keys from the MeshConnect dashboard
4. Note your API Key and API Secret

### 2. Configure the Application

1. Run the application: `./bonus-payout.sh`
2. Select option 1: "Setup API Configuration"
3. Choose your environment (Sandbox for testing, Production for live payouts)
4. Enter your MeshConnect API Key and API Secret
5. Configuration will be saved securely to `.env` file

## Usage

### Main Menu Options

1. **Setup API Configuration** - Configure MeshConnect API credentials
2. **View Available Balance** - Check account balance (requires connected account)
3. **Process Single Bonus Payout** - Process one bonus payment
4. **Process Batch Bonus Payouts** - Process multiple payouts from CSV
5. **View Payout History** - Show recent payout history
6. **Test Connection** - Test API connectivity
7. **Exit** - Exit the application

### Single Bonus Payout (Two-Step Process)

**Step 1: Generate Link Token**
1. Select option 3 from the main menu
2. Enter recipient details:
   - Email address
   - Wallet address (cryptocurrency receiving address)
   - Bonus amount in USD
   - Cryptocurrency symbol (USDC, USDT, ETH, etc.)
   - Network (Ethereum, Polygon, etc.)
   - Description/reason for bonus
3. Copy the generated link token from the output

**Step 2: Complete Payment via MeshConnect Link UI**
1. Open a new terminal window and run: `./serve-web-interface.sh`
2. Open your browser to http://localhost:3000
3. Paste the link token from Step 1
4. Click "Process Payment" to open MeshConnect Link UI modal
5. Connect your Coinbase account and complete the transfer

The MeshConnect Link UI handles the secure connection to Coinbase and executes the cryptocurrency transfer.

### Batch Bonus Payouts (Two-Step Process)

**Step 1: Generate Link Tokens**
1. Prepare a CSV file with the following format:
   ```csv
   email,wallet_address,amount,crypto_symbol,network,description
   john.doe@example.com,0x742d35Cc6634C0532925a3b8D66C2dDc168E7d8f,100.00,USDC,Ethereum,Q4 Performance Bonus
   jane.smith@example.com,0x8ba1f109551bD432803012645Hac136c5a765a13,250.50,USDT,Ethereum,Sales Target Achievement
   ```

2. Select option 4 from the main menu
3. Provide the path to your CSV file
4. The application will process each payout and provide link tokens

**Step 2: Complete Payments via MeshConnect Link UI**
1. For each generated link token, open the web interface: `./serve-web-interface.sh`
2. Process each payment through the web interface
3. Each payment requires connecting to Coinbase and confirming the transfer

**Note:** Batch processing generates multiple link tokens - each must be processed individually through the web interface.

### Using the MeshConnect Link UI

The web interface (`web-interface.html`) provides a user-friendly way to complete payments:

1. **Start the Web Server:**
   ```bash
   ./serve-web-interface.sh
   ```
   - Automatically finds an available port (usually 3000)
   - Opens a local web server
   - Provides step-by-step instructions

2. **Complete Payments:**
   - Paste the link token from the shell script
   - Click "Process Payment"
   - MeshConnect Link UI modal opens
   - Connect your Coinbase account
   - Confirm payment details
   - Execute the transfer

3. **What Happens in the Link UI:**
   - Secure OAuth connection to Coinbase
   - Real-time balance checking
   - Fee calculation and preview
   - Transaction confirmation
   - Transfer execution
   - Receipt and transaction hash

### Creating Sample CSV

You can create a sample CSV file using the utility function:
```bash
# From within the application directory
source lib/utils.sh
create_sample_csv "sample_payouts.csv"
```

## Supported Cryptocurrencies

- **USDC** (USD Coin)
- **USDT** (Tether)
- **ETH** (Ethereum)
- **BTC** (Bitcoin)
- **BNB** (Binance Coin)
- **MATIC** (Polygon)
- **DAI** (Dai Stablecoin)

## Supported Networks

- **Ethereum** - Main Ethereum network
- **Polygon** - Polygon (MATIC) network
- **BSC** - Binance Smart Chain

## File Structure

```
bonus-payout-app/
├── bonus-payout.sh          # Main application script
├── serve-web-interface.sh   # Web server for MeshConnect Link UI
├── web-interface.html       # Web interface for completing payments
├── setup.sh                # Installation and setup script
├── lib/                     # Library files
│   ├── config.sh           # Configuration management
│   ├── api.sh              # MeshConnect API interactions
│   ├── utils.sh            # Utility functions
│   └── logging.sh          # Logging functions
├── logs/                   # Log files
│   ├── app.log            # Application logs
│   ├── payouts.log        # Payout transaction logs
│   └── errors.log         # Error logs
├── data/                  # Data storage
├── sample_payouts.csv      # Example CSV file for batch processing
├── .env                   # API configuration (created after setup)
└── README.md             # This file
```

## Security Considerations

1. **API Credentials**: API keys are stored in `.env` file with restricted permissions (600)
2. **Logging**: Sensitive information is masked in logs
3. **Validation**: All inputs are validated before processing
4. **Secure Storage**: Configuration files use secure file permissions

## How It Works

The application uses MeshConnect's API to create payment link tokens. Here's the flow:

1. **Configuration**: Store your MeshConnect API credentials
2. **Payout Creation**: Generate a link token for each payout with recipient details
3. **Payment Processing**: Share the link token with your finance team
4. **Account Connection**: Finance team uses MeshConnect Link UI to connect Coinbase account
5. **Payment Execution**: Payment is executed from connected Coinbase account to recipient wallet
6. **Logging**: All transactions are logged for audit purposes

## Troubleshooting

### Common Issues

1. **API Connection Failed**
   - Check your API credentials
   - Verify you're using the correct environment (sandbox/production)
   - Ensure internet connectivity

2. **Invalid Wallet Address**
   - Verify the wallet address format
   - Ensure the address supports the selected cryptocurrency

3. **CSV Processing Errors**
   - Check CSV file format matches the required headers
   - Ensure no empty rows or invalid data
   - Verify file permissions

### Log Files

- **Application logs**: `logs/app.log` - General application events
- **Payout logs**: `logs/payouts.log` - All payout transactions
- **Error logs**: `logs/errors.log` - Error messages and failures

### Getting Help

1. Check the log files for detailed error messages
2. Use the "Test Connection" option to verify API connectivity
3. Ensure all requirements are installed
4. Contact MeshConnect support for API-related issues

## Development

### Adding New Features

The application is modular with separate library files:

- `lib/config.sh` - Configuration management
- `lib/api.sh` - API interactions
- `lib/utils.sh` - Utility functions
- `lib/logging.sh` - Logging functionality

### Testing

Always test in the sandbox environment before using in production:

1. Set up sandbox API credentials
2. Use test wallet addresses
3. Verify all functionality works as expected
4. Check log files for any issues

## License

This project is provided as-is for educational and business use. Please ensure compliance with your organization's security policies and local regulations when handling cryptocurrency transactions.

## Support

For application-specific issues, check the logs and troubleshooting section above.
For MeshConnect API issues, contact MeshConnect support at [support@meshconnect.com](mailto:support@meshconnect.com). 