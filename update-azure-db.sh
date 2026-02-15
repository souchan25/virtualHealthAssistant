#!/bin/bash
# Update DATABASE_URL in Azure App Service with properly encoded Supabase connection string

az webapp config appsettings set \
  --resource-group "cpsu-health-assistant_group" \
  --name "cpsu-health-assistant-backend" \
  --settings DATABASE_URL="postgresql://postgres.wnevivjmprtrmxxawrni:3y%2F%2AKq%2Bd26AAd%23%3F@aws-1-ap-northeast-2.pooler.supabase.com:5432/postgres"

echo "✅ DATABASE_URL updated successfully!"
echo "🔄 Restarting App Service..."

az webapp restart \
  --resource-group "cpsu-health-assistant_group" \
  --name "cpsu-health-assistant-backend"

echo "✅ App Service restarted!"
echo "🌐 Your app should now be running at: https://cpsu-health-assistant-backend.azurewebsites.net"
