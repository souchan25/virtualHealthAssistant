#!/bin/bash
# Start Rasa server with the latest trained model
# Run this from the VirtualAssistant root directory

echo "🏥 Starting CPSU Rasa Server"
echo "========================================="
echo ""

# Check if we're in Rasa directory
if [ ! -f "domain.yml" ]; then
    echo "⚠️  Not in Rasa directory. Changing to Rasa/"
    cd Rasa 2>/dev/null || { echo "❌ Rasa directory not found!"; exit 1; }
fi

# Check if models exist
if [ ! -d "models" ] || [ -z "$(ls -A models/*.tar.gz 2>/dev/null)" ]; then
    echo "❌ No trained models found in models/"
    echo ""
    echo "Please train a model first:"
    echo "  rasa train"
    echo ""
    exit 1
fi

# Find the latest model
LATEST_MODEL=$(ls -t models/*.tar.gz 2>/dev/null | head -1)

if [ -z "$LATEST_MODEL" ]; then
    echo "❌ No .tar.gz models found!"
    exit 1
fi

echo "✅ Found trained model:"
echo "   $LATEST_MODEL"
echo ""

# Check if Rasa action server is running
if curl -s http://localhost:5055 > /dev/null 2>&1; then
    echo "✅ Rasa action server is running (port 5055)"
else
    echo "⚠️  Rasa action server is NOT running"
    echo "   Start it in another terminal:"
    echo "   cd Rasa && rasa run actions"
    echo ""
fi

# Start Rasa server
echo "🚀 Starting Rasa server..."
echo "   - Port: 5005"
echo "   - Model: $LATEST_MODEL"
echo "   - CORS: Enabled for all origins"
echo "   - API: Enabled"
echo ""

rasa run \
    --model "$LATEST_MODEL" \
    --enable-api \
    --cors "*" \
    --port 5005 \
    --log-file rasa_server.log \
    --debug

# Note: Add --debug for verbose logging
# Remove --debug for production use
