/**
 * TimeDeck StreamDeck Plugin - Simplified for StreamDeck 7.0.0
 * Connects StreamDeck to TimeDeck native macOS app via HTTP API
 */

// TimeDeck API Configuration
const TIMEDECK_API_BASE = 'http://localhost:8080/api';

// Global variables
let websocket = null;
let pluginUUID = null;

// Action UUIDs
const ACTION_UUIDS = {
    START_ACTIVITY: 'com.timedeck.streamdeck.start-activity',
    END_ACTIVITY: 'com.timedeck.streamdeck.end-activity', 
    ACTIVITY_STATUS: 'com.timedeck.streamdeck.activity-status',
    QUICK_TEMPLATE: 'com.timedeck.streamdeck.quick-template',
    PAUSE_RESUME: 'com.timedeck.streamdeck.pause-resume',
    START_FRESH: 'com.timedeck.streamdeck.start-fresh'
};

// Use native fetch (available in Node.js 18+)
async function makeHTTPRequest(url, method = 'GET', data = null) {
    try {
        const options = {
            method: method,
            headers: {
                'Content-Type': 'application/json',
                'User-Agent': 'TimeDeck-StreamDeck-Plugin/1.0.0'
            }
        };
        
        if (data) {
            options.body = JSON.stringify(data);
        }
        
        const response = await fetch(url, options);
        const jsonData = await response.json();
        return jsonData;
    } catch (error) {
        console.error('HTTP Request Error:', error.message);
        return { success: false, error: error.message };
    }
}

// Utility: TimeDeck API Call
async function callTimeDeckAPI(endpoint, method = 'GET', body = null) {
    try {
        const url = `${TIMEDECK_API_BASE}${endpoint}`;
        console.log(`TimeDeck API: ${method} ${url}`);
        
        const response = await makeHTTPRequest(url, method, body);
        
        if (!response.success) {
            console.error(`TimeDeck API Error: ${response.error || 'Unknown error'}`);
            return null;
        }
        
        return response.data;
    } catch (error) {
        console.error(`TimeDeck API Call Failed: ${error.message}`);
        return null;
    }
}

// Utility: Update button
function updateButton(context, title = null, image = null, showAlert = false) {
    if (!websocket) return;
    
    if (title !== null) {
        websocket.send(JSON.stringify({
            event: 'setTitle',
            context: context,
            payload: { title: title }
        }));
    }
    
    if (showAlert) {
        websocket.send(JSON.stringify({
            event: 'showAlert',
            context: context
        }));
    }
}

// Utility: Show success
function showSuccess(context) {
    if (!websocket) return;
    
    websocket.send(JSON.stringify({
        event: 'showOk',
        context: context
    }));
}

// Action: Start Activity
async function handleStartActivity(context, settings) {
    const activityName = (settings && settings.activityName) || 'New Activity';
    console.log(`Starting activity: ${activityName}`);
    
    const result = await callTimeDeckAPI('/activities/start', 'POST', {
        activity: activityName
    });
    
    if (result) {
        updateButton(context, `Started\\n${activityName}`);
        showSuccess(context);
        console.log(`Successfully started: ${activityName}`);
    } else {
        updateButton(context, 'Failed', null, true);
        console.error(`Failed to start activity: ${activityName}`);
    }
}

// Action: End Activity
async function handleEndActivity(context) {
    console.log('Ending current activity');
    
    const result = await callTimeDeckAPI('/activities/end', 'POST');
    
    if (result) {
        updateButton(context, `Ended\\n${result.activity}`);
        showSuccess(context);
        console.log(`Successfully ended: ${result.activity}`);
    } else {
        updateButton(context, 'No Activity', null, true);
        console.error('Failed to end activity');
    }
}

// Action: Activity Status
async function handleActivityStatus(context) {
    const status = await callTimeDeckAPI('/status');
    
    if (!status) {
        updateButton(context, 'API Error');
        return;
    }
    
    if (status.hasActiveActivity) {
        const activity = status.currentActivity;
        const time = status.elapsedTime;
        const pauseStatus = status.isInBreak ? ' (Paused)' : '';
        updateButton(context, `${activity}\\n${time}${pauseStatus}`);
    } else {
        updateButton(context, 'No Activity\\nTracking');
    }
}

// Action: Quick Template
async function handleQuickTemplate(context, settings) {
    const templateName = (settings && settings.templateName) || 'Development';
    console.log(`Starting template activity: ${templateName}`);
    
    const result = await callTimeDeckAPI('/activities/start', 'POST', {
        activity: templateName
    });
    
    if (result) {
        updateButton(context, `${templateName}\\nStarted`);
        showSuccess(context);
    } else {
        updateButton(context, 'Failed', null, true);
    }
}

// Action: Pause/Resume
async function handlePauseResume(context) {
    console.log('Toggling pause/resume');
    
    const result = await callTimeDeckAPI('/activities/pause', 'POST');
    
    if (result) {
        const status = result.isInBreak ? 'Paused' : 'Resumed';
        updateButton(context, `${status}\\n${result.activity}`);
        showSuccess(context);
    } else {
        updateButton(context, 'No Activity', null, true);
    }
}

// Action: Start Fresh
async function handleStartFresh(context) {
    console.log('Starting fresh');
    
    const result = await callTimeDeckAPI('/activities/fresh', 'POST');
    
    if (result) {
        updateButton(context, 'Fresh Start\\nComplete');
        showSuccess(context);
    } else {
        updateButton(context, 'Failed', null, true);
    }
}

// Status context management
let statusContexts = new Set();

function addStatusContext(context) {
    statusContexts.add(context);
}

function removeStatusContext(context) {
    statusContexts.delete(context);
}

async function updateAllStatusContexts() {
    for (const context of statusContexts) {
        await handleActivityStatus(context);
    }
}

// WebSocket Event Handlers
function connectElgatoStreamDeckSocket(inPort, inPluginUUID, inRegisterEvent, inInfo) {
    pluginUUID = inPluginUUID;
    console.log(`TimeDeck Plugin: Connecting to StreamDeck on port ${inPort}`);
    
    // Connect to Stream Deck using native WebSocket
    websocket = new WebSocket(`ws://localhost:${inPort}`);
    
    websocket.onopen = () => {
        console.log('TimeDeck Plugin: Connected to StreamDeck');
        
        // Register plugin
        websocket.send(JSON.stringify({
            event: inRegisterEvent,
            uuid: inPluginUUID
        }));
        
        // Start periodic status updates (every 5 seconds)
        setInterval(updateAllStatusContexts, 5000);
    };
    
    websocket.onclose = () => {
        console.log('TimeDeck Plugin: StreamDeck connection closed');
    };
    
    websocket.onerror = (error) => {
        console.error('TimeDeck Plugin: WebSocket error:', error);
    };
    
    websocket.onmessage = (event) => {
        try {
            const jsonObj = JSON.parse(event.data);
            const { event: eventType, action, context, payload } = jsonObj;
            
            console.log(`TimeDeck Plugin: Received event: ${eventType}, action: ${action}`);
            
            // Handle different events
            switch (eventType) {
                case 'keyDown':
                    handleKeyDown(action, context, payload);
                    break;
                    
                case 'willAppear':
                    if (action === ACTION_UUIDS.ACTIVITY_STATUS) {
                        addStatusContext(context);
                        handleActivityStatus(context);
                    }
                    break;
                    
                case 'willDisappear':
                    if (action === ACTION_UUIDS.ACTIVITY_STATUS) {
                        removeStatusContext(context);
                    }
                    break;
            }
        } catch (error) {
            console.error('TimeDeck Plugin: Error parsing message:', error);
        }
    });
}

// Handle key down events
async function handleKeyDown(action, context, payload) {
    const settings = (payload && payload.settings) || {};
    
    switch (action) {
        case ACTION_UUIDS.START_ACTIVITY:
            await handleStartActivity(context, settings);
            break;
            
        case ACTION_UUIDS.END_ACTIVITY:
            await handleEndActivity(context);
            break;
            
        case ACTION_UUIDS.ACTIVITY_STATUS:
            await handleActivityStatus(context);
            break;
            
        case ACTION_UUIDS.QUICK_TEMPLATE:
            await handleQuickTemplate(context, settings);
            break;
            
        case ACTION_UUIDS.PAUSE_RESUME:
            await handlePauseResume(context);
            break;
            
        case ACTION_UUIDS.START_FRESH:
            await handleStartFresh(context);
            break;
            
        default:
            console.log(`TimeDeck Plugin: Unknown action: ${action}`);
    }
}

// Entry point
console.log('TimeDeck StreamDeck Plugin Loaded - Simplified Version for StreamDeck 7.0.0');