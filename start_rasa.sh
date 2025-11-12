#!/bin/bash
# Quick start script for CPSU Virtual Health Assistant

echo "🏥 CPSU Virtual Health Assistant - Quick Start"
echo "=============================================="
echo ""

# Check if virtual environment is activated
if [[ "$VIRTUAL_ENV" == "" ]]; then
    echo "⚠️  Virtual environment not activated!"
    echo "Run: source venv/Scripts/activate"
    exit 1
fi

echo "✅ Virtual environment: Active"
echo ""

# Function to check if Django is running
check_django() {
    if curl -s http://localhost:8000 > /dev/null 2>&1; then
        echo "✅ Django is running on http://localhost:8000"
        return 0
    else
        echo "❌ Django is NOT running"
        echo "   Start it with: cd Django && python manage.py runserver"
        return 1
    fi
}

# Function to check if Rasa action server is running
check_rasa_actions() {
    if curl -s http://localhost:5055 > /dev/null 2>&1; then
        echo "✅ Rasa action server is running on http://localhost:5055"
        return 0
    else
        echo "❌ Rasa action server is NOT running"
        echo "   Start it with: cd Rasa && rasa run actions"
        return 1
    fi
}

# Function to train Rasa
train_rasa() {
    echo ""
    echo "📚 Training Rasa model..."
    echo "This will take 2-3 minutes..."
    cd Rasa
    rasa train
    cd ..
}

# Function to start Rasa shell
start_rasa_shell() {
    echo ""
    echo "💬 Starting Rasa interactive shell..."
    cd Rasa
    rasa shell
}

# Function to start Rasa server
start_rasa_server() {
    echo ""
    echo "🤖 Starting Rasa server..."
    cd Rasa
    rasa run --enable-api --cors "*"
}

# Main menu
echo "What would you like to do?"
echo ""
echo "1) Train Rasa model (first time setup)"
echo "2) Start Rasa shell (interactive testing)"
echo "3) Start Rasa server (API mode)"
echo "4) Check service status"
echo "5) Exit"
echo ""
read -p "Enter choice [1-5]: " choice

case $choice in
    1)
        train_rasa
        ;;
    2)
        check_django
        check_rasa_actions
        start_rasa_shell
        ;;
    3)
        check_django
        check_rasa_actions
        start_rasa_server
        ;;
    4)
        check_django
        check_rasa_actions
        ;;
    5)
        echo "Goodbye!"
        exit 0
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac
