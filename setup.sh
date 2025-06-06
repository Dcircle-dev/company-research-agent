#!/bin/bash

# Text styling
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Version comparison function
version_compare() {
    echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'
}

echo -e "${BOLD}🚀 Welcome to the Agentic Company Researcher Setup!${NC}\n"

# Check if Python 3.11+ is installed
echo -e "${BLUE}Checking Python version...${NC}"
if command -v python3 >/dev/null 2>&1; then
    python_version=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
    if [ "$(version_compare "$python_version")" -ge "$(version_compare "3.11")" ]; then
        echo -e "${GREEN}✓ Python $python_version is installed${NC}"
    else
        echo "❌ Python 3.11 or higher is required. Current version: $python_version"
        echo "Please install Python 3.11 or higher from https://www.python.org/downloads/"
        exit 1
    fi
else
    echo "❌ Python 3 is not installed"
    echo "Please install Python 3.11 or higher from https://www.python.org/downloads/"
    exit 1
fi

# Check if Node.js 18+ is installed
echo -e "\n${BLUE}Checking Node.js version...${NC}"
if command -v node >/dev/null 2>&1; then
    node_version=$(node -v | cut -d'v' -f2)
    if [ "$(version_compare "$node_version")" -ge "$(version_compare "18.0.0")" ]; then
        echo -e "${GREEN}✓ Node.js $node_version is installed${NC}"
    else
        echo "❌ Node.js 18 or higher is required. Current version: $node_version"
        echo "Please install Node.js 18 or higher from https://nodejs.org/"
        exit 1
    fi
else
    echo "❌ Node.js is not installed"
    echo "Please install Node.js 18 or higher from https://nodejs.org/"
    exit 1
fi

echo -e "\n${BLUE}Setting up Python virtual environment...${NC}"
uv init
source .venv/bin/activate
echo -e "${GREEN}✓ Virtual environment created and activated${NC}"

# Install Python dependencies in venv
echo -e "\n${BLUE}Installing Python dependencies in virtual environment...${NC}"
uv pip install -r requirements.txt
uv add -r requirements.txt
echo -e "${GREEN}✓ Python dependencies installed${NC}"

# Install Node.js dependencies
echo -e "\n${BLUE}Installing Node.js dependencies...${NC}"
cd ui
npm install
# Create or overwrite .env.development for frontend dev environment
cat > .env.development << EOL
VITE_API_URL=http://localhost:8000
VITE_WS_URL=ws://localhost:8000
EOL
cd ..
echo -e "${GREEN}✓ Node.js dependencies installed${NC}"

# Setup .env file
echo -e "\n${BLUE}Setting up environment variables...${NC}"
if [ -f ".env" ]; then
    echo "Found existing .env file. Would you like to overwrite it? (y/n)"
    read -r overwrite
    if [ "$overwrite" != "y" ]; then
        echo "Keeping existing .env file"
    else
        setup_env=true
    fi
else
    setup_env=true
fi

if [ "$setup_env" = true ]; then
    echo -e "\nPlease enter your API keys:"
    echo -n "Tavily API Key: "
    read -r tavily_key
    echo -n "Google Gemini API Key: "
    read -r gemini_key
    echo -n "OpenAI API Key: "
    read -r openai_key
    echo -n "MongoDB URI (optional - press enter to skip): "
    read -r mongodb_uri

    # Create .env file
    cat > .env << EOL
TAVILY_API_KEY=$tavily_key
GEMINI_API_KEY=$gemini_key
OPENAI_API_KEY=$openai_key
EOL

    # Add MongoDB URI if provided
    if [ ! -z "$mongodb_uri" ]; then
        echo "MONGODB_URI=$mongodb_uri" >> .env
    fi

    echo -e "${GREEN}✓ Environment variables saved to .env${NC}"
fi

# Final instructions and server startup options
echo -e "\n${BOLD}🎉 Setup complete!${NC}"
echo -e "\n${BLUE}Virtual environment is now activated and ready to use${NC}"

# Ask about starting servers
echo -e "\n${BLUE}Would you like to start the application servers now? [Y/n]${NC}"
read -r start_servers
start_servers=${start_servers:-Y}

if [[ $start_servers =~ ^[Yy]$ ]]; then
    echo -e "\n${GREEN}Starting backend server...${NC}"
    uvicorn application:app --reload --port 8000 &
    
    # Store backend PID
    backend_pid=$!
    
    # Wait a moment for backend to start
    sleep 2
    
    # Start frontend server
    echo -e "\n${GREEN}Starting frontend server...${NC}"
    cd ui
    npm run dev &
    frontend_pid=$!
    cd ..
    
    echo -e "\n${GREEN}Servers are starting up! The application will be available at:${NC}"
    echo -e "${BOLD}http://localhost:5173${NC}"
    
    # Add trap to handle script termination
    trap 'kill $backend_pid $frontend_pid 2>/dev/null' EXIT
    
    # Keep script running until user stops it
    echo -e "\n${BLUE}Press Ctrl+C to stop the servers${NC}"
    wait
else
    echo -e "\n${BOLD}To start the application manually:${NC}"
    echo -e "\n1. Start the backend server:"
    echo "   uvicorn application:app --reload --port 8000"
    echo -e "\n2. In a new terminal, start the frontend:"
    echo "   cd ui"
    echo "   npm run dev"
    echo -e "\n3. Access the application at ${BOLD}http://localhost:5173${NC}"
fi

echo -e "\n${BOLD}Need help?${NC}"
echo "- Documentation: README.md"
echo "- Issues: https://github.com/pogjester/tavily-company-research/issues"
echo -e "\n${GREEN}Happy researching! 🚀${NC}" 