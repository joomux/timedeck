// Minimal test plugin
console.log('Test Plugin: Starting up');

function connectElgatoStreamDeckSocket(inPort, inPluginUUID, inRegisterEvent, inInfo) {
    console.log('Test Plugin: Connecting to StreamDeck');
    
    // Very basic connection test
    const websocket = new WebSocket(`ws://localhost:${inPort}`);
    
    websocket.onopen = () => {
        console.log('Test Plugin: Connected successfully');
        
        websocket.send(JSON.stringify({
            event: inRegisterEvent,
            uuid: inPluginUUID
        }));
    };
    
    websocket.onmessage = (event) => {
        console.log('Test Plugin: Received message:', event.data);
    };
    
    websocket.onerror = (error) => {
        console.log('Test Plugin: WebSocket error:', error);
    };
}

console.log('Test Plugin: Loaded');
