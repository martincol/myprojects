const clock = document.querySelector('.clock');
const hourHand = document.getElementById('hourHand');
const minuteHand = document.getElementById('minuteHand');
const digitalDisplay = document.getElementById('digital-clock-display'); // Get digital display element
const quizInstructions = document.getElementById('quiz-instructions');
const quizButton = document.getElementById('quiz-button');
const quizFeedback = document.getElementById('quiz-feedback');

// Delay calculation until needed or after layout
let clockRect, clockCenterX, clockCenterY, clockRadius;

let isDragging = false;
let activeHand = null;
let currentHourAngle = 0; // Store angles to handle transitions
let currentMinuteAngle = 0;

// Quiz State
let quizActive = false;
let targetHour = 0;
let targetMinute = 0;

const rainbowColors = [
    '#FF0000', // 1 (Red)
    '#FF7F00', // 2 (Orange)
    '#FFFF00', // 3 (Yellow)
    '#00FF00', // 4 (Green)
    '#00FFFF', // 5 (Cyan)
    '#0000FF', // 6 (Blue)
    '#8B00FF', // 7 (Violet) - Using Indigo/Violet mix
    '#FF00FF', // 8 (Magenta)
    '#FF1493', // 9 (Deep Pink)
    '#32CD32', // 10 (Lime Green)
    '#FFA500', // 11 (Orange - reusing)
    '#DC143C'  // 12 (Crimson)
];

function updateClockCenter() {
    clockRect = clock.getBoundingClientRect();
    // Use scroll offsets for accuracy if the clock isn't fixed at the top-left
    clockCenterX = clockRect.left + window.scrollX + clockRect.width / 2;
    clockCenterY = clockRect.top + window.scrollY + clockRect.height / 2;
    clockRadius = clockRect.width / 2; // Assuming width and height are the same
}

// --- Draw Clock Face Elements ---

function createClockElements() {
    const markerContainer = document.createDocumentFragment();
    const numberContainer = document.createDocumentFragment();

    // Calculate radii dynamically based on current clock size
    updateClockCenter(); // Get initial dimensions
    const numberRadius = clockRadius * 0.75;
    const markerOuterRadius = clockRadius * 0.98;
    const minuteMarkerLength = clockRadius * 0.05; // Length based on radius
    const fiveMinMarkerLength = clockRadius * 0.08;


    for (let i = 0; i < 60; i++) {
        const angle = (i / 60) * 360;
        const angleRad = ((angle - 90) * Math.PI) / 180; // Offset by -90 for 12 at top

        // Minute Markers
        const marker = document.createElement('div');
        marker.classList.add('minute-marker');
        let markerLen = minuteMarkerLength;
        if (i % 5 === 0) {
            marker.classList.add('five-min');
            markerLen = fiveMinMarkerLength;

            // Add hour numbers only for 5-minute marks
            const hour = (i / 5) === 0 ? 12 : (i / 5);
            // Get rainbow color based on hour (1-12)
            const colorIndex = (hour - 1) % 12; // 0-11 index
            const rainbowColor = rainbowColors[colorIndex];

            const numX = numberRadius * Math.cos(angleRad);
            const numY = numberRadius * Math.sin(angleRad);

            const numberDiv = document.createElement('div');
            numberDiv.classList.add('hour-number');
            numberDiv.textContent = hour;
            numberDiv.style.left = `calc(50% + ${numX}px)`;
            numberDiv.style.top = `calc(50% + ${numY}px)`;
            // Optional: Rotate numbers back to be upright if desired
            // numberDiv.style.transform = `translate(-50%, -50%) rotate(${-angle}deg)`;
            numberDiv.style.color = rainbowColor; // Apply rainbow color
            numberContainer.appendChild(numberDiv);

            // Apply same color to the 5-minute marker
            marker.style.backgroundColor = rainbowColor;
        }

        const markerX = (clockRadius - markerLen / 2) * Math.cos(angleRad); // Position marker center
        const markerY = (clockRadius - markerLen / 2) * Math.sin(angleRad);

        marker.style.height = `${markerLen}px`; // Set dynamic height
        marker.style.left = `calc(50% + ${markerX}px)`;

        // Set a uniform vertical offset for all markers
        const verticalOffset = 5;

        // Apply the offset to the top position
        marker.style.top = `calc(50% + ${markerY}px + ${verticalOffset}px)`;

        // Rotate marker to point towards the center
        marker.style.transform = `translate(-50%, -50%) rotate(${angle}deg)`;

        markerContainer.appendChild(marker);
    }
    // Add markers and numbers to the clock div
    clock.appendChild(markerContainer);
    clock.appendChild(numberContainer);
}


// --- Hand Movement Logic ---

// Function to update the digital clock display
function updateDigitalClock(hourAngle, minuteAngle) {
    // Calculate minutes (0-59)
    const minutes = Math.round((minuteAngle % 360) / 6 + 60) % 60;

    // Calculate hours (1-12)
    // Based on the hour hand's angle, considering it moves 360 deg in 12*60 mins
    const totalMinutesPast12 = (hourAngle / 360) * 720;
    // Get the hour value (0-11)
    const hourValueRaw = Math.floor(totalMinutesPast12 / 60);
    // Convert 0-11 to 1-12, mapping 0 to 12
    const hours = ((hourValueRaw + 11) % 12) + 1;

    // Format with leading zeros
    const formattedHours = String(hours).padStart(2, '0');
    const formattedMinutes = String(minutes).padStart(2, '0');

    digitalDisplay.textContent = `${formattedHours}:${formattedMinutes}`;
}

function updateClockHands(hourAngle, minuteAngle) {
    // Normalize angles before applying
    currentHourAngle = hourAngle % 360;
    currentMinuteAngle = minuteAngle % 360;
    hourHand.style.transform = `translateX(-50%) rotate(${currentHourAngle}deg)`;
    minuteHand.style.transform = `translateX(-50%) rotate(${currentMinuteAngle}deg)`;

    // Update the digital display whenever hands move
    updateDigitalClock(currentHourAngle, currentMinuteAngle);
}

function calculateAngleFromCenter(event) {
    updateClockCenter(); // Ensure center is up-to-date
    const mouseX = event.clientX;
    const mouseY = event.clientY;

    // Calculate angle relative to the vertical (12 o'clock) using screen coordinates
    const deltaX = mouseX - clockCenterX;
    const deltaY = mouseY - clockCenterY;
    const angleRad = Math.atan2(deltaX, -deltaY); // Y is inverted in screen coordinates, use -deltaY
    let angleDeg = angleRad * (180 / Math.PI);

    // Normalize angle to be between 0 and 360 (clockwise from top)
    angleDeg = (angleDeg + 360) % 360;

    return angleDeg;
}

function handleMouseMove(event) {
    if (!isDragging || !activeHand) return;

    const angleDeg = calculateAngleFromCenter(event);

    let newHourAngle, newMinuteAngle;

    if (activeHand === minuteHand) {
        // Snap minute hand angle to the nearest minute (every 6 degrees)
        const minuteValue = Math.round(angleDeg / 6) % 60;
        newMinuteAngle = minuteValue * 6;

        // Calculate the change in minute angle (handle wrap around 360)
        let minuteAngleChange = newMinuteAngle - currentMinuteAngle;
        if (minuteAngleChange > 180) minuteAngleChange -= 360;
        if (minuteAngleChange < -180) minuteAngleChange += 360;

        // Hour hand moves 1/12th the speed of the minute hand
        newHourAngle = (currentHourAngle + minuteAngleChange / 12) % 360;

    } else if (activeHand === hourHand) {
        // Calculate the "raw" hour value including fraction (0-11.99...)
        const rawHourValue = (angleDeg / 360) * 12;

        // Calculate corresponding minute value based on the fractional part of the hour angle
        // Hour angle relates to total minutes past 12:00. angle = (totalMinutes / 720) * 360
        const totalMinutesPast12 = (angleDeg / 360) * 720;
        const minuteValue = Math.round(totalMinutesPast12) % 60; // Get the minute part and round

        // Snap the derived minute angle
        newMinuteAngle = (minuteValue * 6) % 360;

        // Recalculate the hour angle based on the snapped minute angle to maintain consistency
        // Extract the whole hour from the original angle first
        const wholeHour = Math.floor(rawHourValue);
        newHourAngle = ((wholeHour + minuteValue / 60) / 12) * 360;
    }

    updateClockHands(newHourAngle, newMinuteAngle);
}


function startDrag(event) {
    const target = event.target;
    // Check if the clicked element is a hand-grabber
     if (target.classList.contains('hand-grabber')) {
         isDragging = true;
         // Set activeHand to the parent element (the actual hand div)
         activeHand = target.parentElement;
         updateClockCenter(); // Get center coords at drag start
         // Read current angles from the active hand's style
         currentHourAngle = parseFloat(hourHand.style.transform.split('rotate(')[1] || '0');
         currentMinuteAngle = parseFloat(minuteHand.style.transform.split('rotate(')[1] || '0');

         activeHand.style.zIndex = 11; // Bring dragged hand to front
         // Attach move/up listeners to the document
         document.addEventListener('mousemove', handleMouseMove);
         document.addEventListener('mouseup', stopDrag);
         document.addEventListener('mouseleave', stopDrag);
         event.preventDefault();
     }
}

function stopDrag() {
    if (isDragging) {
        if(activeHand) {
            activeHand.style.zIndex = 10; // Reset z-index
        }
        isDragging = false;
        activeHand = null;
        // Remove document listeners
        document.removeEventListener('mousemove', handleMouseMove);
        document.removeEventListener('mouseup', stopDrag);
        document.removeEventListener('mouseleave', stopDrag);
    }
}

// --- Quiz Logic ---

function generateRandomTime() {
    const hour = Math.floor(Math.random() * 12) + 1; // 1-12
    const minute = Math.floor(Math.random() * 12) * 5; // 0, 5, 10, ..., 55
    return { hour, minute };
}

function formatTime(hour, minute) {
    const formattedHours = String(hour).padStart(2, '0');
    const formattedMinutes = String(minute).padStart(2, '0');
    return `${formattedHours}:${formattedMinutes}`;
}

function startQuiz() {
    quizActive = true;
    const time = generateRandomTime();
    targetHour = time.hour;
    targetMinute = time.minute;

    quizInstructions.textContent = `Set the clock to: ${formatTime(targetHour, targetMinute)}`;
    quizFeedback.textContent = '';
    quizFeedback.className = ''; // Clear feedback styling
    quizButton.textContent = 'Check Answer';
}

function checkAnswer() {
    if (!quizActive) return;

    // Calculate the time currently set on the analog clock
    const currentSetMinutes = Math.round((currentMinuteAngle % 360) / 6 + 60) % 60;

    // Calculate the hour based on the *precise* hour hand angle
    const totalMinutesPast12 = (currentHourAngle / 360) * 720;
    const hourValueRaw = Math.floor(totalMinutesPast12 / 60);
    const currentSetHours = ((hourValueRaw + 11) % 12) + 1;

    // Check if the minute hand is correct (within 1 minute due to snapping)
    const minuteMatch = currentSetMinutes === targetMinute;

    // Check if the hour hand is roughly correct (within ~15 mins range)
    // Calculate the expected hour angle for the target time
    const expectedHourAngle = (((targetHour % 12) + targetMinute / 60) / 12) * 360;
    const hourDifference = Math.abs(currentHourAngle - expectedHourAngle);
    // Allow a tolerance (e.g., 7.5 degrees = 15 minutes on hour hand movement)
    const hourMatch = Math.min(hourDifference, 360 - hourDifference) < 7.5;

    if (minuteMatch && hourMatch) {
        quizFeedback.textContent = 'Correct!';
        quizFeedback.className = 'correct';
        quizButton.textContent = 'Next Question';
        quizActive = false; // Stop current quiz round, ready for next
    } else {
        quizFeedback.textContent = 'Try Again!';
        quizFeedback.className = 'incorrect';
        // Keep button as 'Check Answer'
    }
}

// --- Initial Setup ---

// Wait for the DOM to be fully loaded and rendered
document.addEventListener('DOMContentLoaded', () => {
    createClockElements();

    // Set initial time
    const initialHour = 12;
    const initialMinute = 0;
    const initialHourAngle = (((initialHour % 12) + initialMinute / 60) / 12) * 360;
    const initialMinuteAngle = (initialMinute / 60) * 360;
    updateClockHands(initialHourAngle, initialMinuteAngle);
    // Initial digital clock update is now handled within updateClockHands

    // Add event listeners specifically to the grabbers inside the hands
    hourHand.querySelector('.hand-grabber').addEventListener('mousedown', startDrag);
    minuteHand.querySelector('.hand-grabber').addEventListener('mousedown', startDrag);

    // Recalculate clock center on resize
    window.addEventListener('resize', updateClockCenter);

    // Quiz button listener
    quizButton.addEventListener('click', () => {
        if (quizActive) {
            checkAnswer();
        } else {
            startQuiz();
        }
    });
}); 