
# Medium Daily Digest Summarizer - n8n Workflow

This n8n workflow automatically processes Medium Daily Digest emails, extracts article links, summarizes each article, and saves the results as a markdown file to Google Drive.

## Features

- **Scheduled Execution**: Runs daily at 09:30 Europe/Madrid timezone
- **Email Processing**: Fetches the latest Medium Daily Digest from `noreply@medium.com`
- **Link Extraction**: Automatically extracts Medium article URLs from email HTML
- **Content Summarization**: Fetches each article and creates 2-3 sentence summaries
- **Markdown Generation**: Creates a formatted markdown file with titles, summaries, and links
- **Google Drive Integration**: Saves files to a "medium_com" folder with date-stamped filenames
- **Error Handling**: Includes comprehensive error handling and notifications
- **Rate Limiting**: Implements delays between article fetches to avoid being blocked

## Prerequisites

Before importing this workflow, ensure you have:

1. **n8n Instance**: Self-hosted n8n running via Docker on Mac (or any other setup)
2. **Gmail Access**: OAuth credentials configured for Gmail API access
3. **Google Drive Access**: OAuth credentials configured for Google Drive API access
4. **Medium Daily Digest Subscription**: Ensure you're subscribed to Medium's Daily Digest emails

## Installation Instructions

### Step 1: Import the Workflow

1. Open your n8n instance in a web browser
2. Click on "Workflows" in the left sidebar
3. Click the "+" button to create a new workflow
4. Click on the three dots menu (⋯) in the top right
5. Select "Import from File" or "Import from URL"
6. Upload the `medium_daily_digest_summarizer.json` file
7. The workflow will be imported with all nodes and connections

### Step 2: Configure Gmail Credentials

1. In the n8n interface, go to "Settings" → "Credentials"
2. Click "Create New Credential"
3. Select "Gmail OAuth2 API"
4. Follow these steps:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select an existing one
   - Enable the Gmail API
   - Create OAuth 2.0 credentials (Web application)
   - Add your n8n instance URL to authorized redirect URIs (e.g., `http://localhost:5678/rest/oauth2-credential/callback`)
   - Copy the Client ID and Client Secret to n8n
   - Complete the OAuth flow by clicking "Connect my account"

### Step 3: Configure Google Drive Credentials

1. In n8n, create another new credential
2. Select "Google Drive OAuth2 API"
3. Follow similar steps as Gmail:
   - In Google Cloud Console, enable the Google Drive API
   - Use the same OAuth 2.0 credentials or create new ones
   - Add the Client ID and Client Secret to n8n
   - Complete the OAuth flow

### Step 4: Set Up Google Drive Folder

1. In your Google Drive, create a folder named "medium_com"
2. Right-click the folder and select "Share"
3. Copy the folder ID from the URL (the long string after `/folders/`)
4. In the n8n workflow, find the "Upload to Google Drive" node
5. Replace "medium_com" in the `parentIds` parameter with your actual folder ID

**Alternative**: You can also use the folder name "medium_com" directly if you prefer, but using the folder ID is more reliable.

### Step 5: Configure Email Settings (Optional)

The workflow is pre-configured to look for emails from `noreply@medium.com` to `pedroh.r99@gmail.com`. To customize:

1. Open the "Fetch Medium Digest" node
2. Modify the query in the filters section:

   ```text
   from:noreply@medium.com to:your-email@gmail.com subject:"Daily Digest" is:unread
   ```

3. Replace `your-email@gmail.com` with your actual email address

### Step 6: Test the Workflow

1. Before activating the schedule, test the workflow manually:
   - Click on the "Daily Schedule" node
   - Click "Execute Node" to run a test
   - Check each node's output to ensure everything works correctly

2. If you don't have a recent Medium Daily Digest email:
   - Temporarily modify the Gmail query to remove `is:unread` and `receivedAfter` filters
   - Test with an older digest email
   - Remember to restore the original filters afterward

### Step 7: Activate the Workflow

1. Once testing is successful, activate the workflow:
   - Toggle the "Active" switch in the top right corner
   - The workflow will now run automatically at 09:30 Europe/Madrid time daily

## Workflow Components Explained

### 1. Daily Schedule (Schedule Trigger)

- **Cron Expression**: `30 9 * * *` (09:30 daily)
- **Timezone**: Europe/Madrid
- Triggers the entire workflow automatically

### 2. Fetch Medium Digest (Gmail Node)

- Searches for the latest unread Medium Daily Digest email
- Filters by sender, recipient, and date
- Returns full email content including HTML

### 3. Check Email Exists (IF Node)

- Validates that an email was found
- Branches workflow execution based on result

### 4. Extract Article Links (Code Node)

- Parses HTML content from the email
- Uses regex to find Medium article URLs
- Filters out non-article links (profiles, topics, etc.)
- Limits to 10 articles to prevent rate limiting

### 5. Process Articles One by One (Split in Batches)

- Processes articles sequentially to avoid overwhelming servers
- Batch size of 1 ensures proper rate limiting

### 6. Fetch Article Content (HTTP Request)

- Retrieves full HTML content of each article
- Includes proper headers to avoid blocking
- Has retry logic for failed requests

### 7. Rate Limit Wait (Wait Node)

- Adds a 1-minute delay between article fetches
- Prevents being blocked by Medium's servers

### 8. Extract Title & Summarize (Code Node)

- Extracts article title from HTML
- Removes Medium branding from titles
- Extracts article content and creates summaries
- Handles various HTML structures and edge cases

### 9. Collect All Articles (Aggregate Node)

- Combines all processed articles into a single data structure
- Prepares data for markdown generation

### 10. Create Markdown File (Code Node)

- Generates formatted markdown with all articles
- Includes titles, summaries, links, and metadata
- Creates date-stamped filename

### 11. Upload to Google Drive (Google Drive Node)

- Uploads the markdown file to the specified folder
- Uses the configured Google Drive credentials

### 12. Success/Error Notifications (NoOp Nodes)

- Provides feedback on workflow execution
- Can be replaced with actual notification nodes (email, Slack, etc.)

## Customization Options

### Change Schedule

To modify when the workflow runs:

1. Edit the "Daily Schedule" node
2. Change the cron expression:
   - `0 8 * * *` for 08:00 daily
   - `30 18 * * 1-5` for 18:30 on weekdays only
   - `0 9 * * 0` for 09:00 on Sundays only

### Modify Summary Length

In the "Extract Title & Summarize" node, adjust the summary logic:

- Change `sentences.slice(0, 3)` to `sentences.slice(0, 2)` for shorter summaries
- Modify the character limit from 200 to your preferred length

### Add AI-Powered Summaries

For better summaries, you can integrate with OpenAI:

1. Add an OpenAI credential to n8n
2. Replace the summary logic in "Extract Title & Summarize" with an OpenAI API call
3. Use a prompt like: "Summarize this article in 2-3 sentences: [article content]"

### Change Output Format

To generate different file formats:

- **CSV**: Replace the markdown generation with CSV formatting
- **JSON**: Output the articles array directly as JSON
- **HTML**: Create an HTML report instead of markdown

### Add Email Notifications

Replace the NoOp notification nodes with actual email nodes:

1. Add a "Send Email" node after success/error
2. Configure with your email credentials
3. Send summary reports or error alerts

## Troubleshooting

### Common Issues

#### 1. No emails found

- Check that you're subscribed to Medium Daily Digest
- Verify the email address in the Gmail query
- Ensure emails aren't being filtered to spam

#### 2. Articles not loading

- Some articles may be behind paywalls
- Rate limiting may be too aggressive - increase wait times
- Check if Medium has blocked the requests

#### 3. Google Drive upload fails

- Verify folder permissions and ID
- Check Google Drive API quotas
- Ensure OAuth credentials are valid

#### 4. Workflow doesn't run on schedule

- Check n8n timezone settings
- Verify the cron expression
- Ensure the workflow is activated

### Debug Mode

To debug issues:

1. Run the workflow manually node by node
2. Check the execution log for each node
3. Use the "Pin Data" feature to test with sample data
4. Enable verbose logging in n8n settings

### Performance Optimization

- Reduce the number of articles processed (change limit in Extract Links node)
- Increase wait times if getting blocked
- Use webhook triggers instead of polling for better performance

## Security Considerations

- **Credentials**: Never share your OAuth credentials or workflow exports containing them
- **Rate Limiting**: Respect Medium's servers by not reducing wait times too much
- **Data Privacy**: Be mindful of what data you're processing and storing
- **Access Control**: Limit Google Drive folder access to necessary users only

## Support and Updates

This workflow was created for n8n version 1.x. For updates or issues:

1. Check the n8n community forum for similar workflows
2. Review n8n documentation for node updates
3. Test thoroughly after any n8n version upgrades
4. Consider backing up your workflow configurations regularly

## License

This workflow is provided as-is for educational and personal use. Please respect Medium's terms of service and rate limits when using this automation.

---

**Created**: January 2025
**n8n Version**: 1.x
**Last Updated**: January 2025
