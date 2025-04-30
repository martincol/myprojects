const hearWordButton = document.getElementById('hear-word-button');
const spellingInput = document.getElementById('spelling-input');
const checkButton = document.getElementById('check-button');
const feedback = document.getElementById('feedback');

// Simple word list - you can expand this!
const wordLists = {
    veryEasy: [
        'a', 'I', 'is', 'it', 'in', 'at', 'on', 'go', 'up', 'me', 'my', 'to', 'we', 'do',
        'am', 'an', 'as', 'ax', 'be', 'by', 'he', 'hi', 'if', 'of', 'or', 'ox', 'so', 'us',
        'ad', 'ah', 'ai', 'ay', 'aw', 'eh', 'em', 'en', 'er', 'ex', 'ha', 'ho', 'id', 'jo',
        'la', 'li', 'lo', 'ma', 'mu', 'ne', 'no', 'nu', 'od', 'oe', 'oh', 'oi', 'om', 'op',
        'ow', 'oy', 'pa', 'pe', 'pi', 'po', 're', 'sh', 'si', 'st', 'ta', 'ti', 'uh', 'um',
        'un', 'ut', 'wo', 'xi', 'xu', 'ya', 'ye', 'yo', 'za', 'bad', 'bed', 'big', 'box',
        'boy', 'bug', 'bus', 'but', 'buy', 'can', 'cap', 'car', 'cat', 'cow', 'cub', 'cup',
        'cut', 'dad', 'day', 'den', 'did', 'dig', 'dip', 'dog', 'dot', 'dry', 'dub', 'dug'
        // Added 100 very easy words
    ],
    easy: [
        'cat', 'dog', 'sun', 'run', 'hat', 'top', 'big', 'red', 'one', 'two',
        'see', 'bed', 'man', 'pig', 'box', 'car', 'bus', 'pen', 'cup', 'map',
        'fan', 'jam', 'log', 'mop', 'net', 'pan', 'rug', 'sit', 'ten', 'web',
        'yes', 'yet', 'zip', 'zoo', 'ask', 'and', 'all', 'are', 'ant', 'arm',
        'art', 'bag', 'bat', 'bee', 'boy', 'bug', 'can', 'cap', 'cow', 'cry',
        'dad', 'day', 'did', 'dry', 'eat', 'egg', 'far', 'fat', 'fin', 'fly',
        'for', 'fox', 'fun', 'get', 'gig', 'god', 'got', 'gum', 'had', 'has',
        'hen', 'her', 'him', 'his', 'hit', 'hot', 'how', 'hug', 'ice', 'ill',
        'ink', 'its', 'jet', 'job', 'key', 'kid', 'kin', 'kit', 'lap', 'leg',
        'let', 'lip', 'low', 'mad', 'mat', 'men', 'mix', 'mom', 'mud', 'nap'
    ],
    medium: [
        'apple', 'house', 'mouse', 'table', 'chair', 'happy', 'water', 'light', 'green', 'school',
        'friend', 'jump', 'play', 'book', 'tree', 'cloud', 'storm', 'train', 'plane', 'bread',
        'sugar', 'dream', 'sleep', 'smile', 'laugh', 'think', 'write', 'read', 'speak', 'listen',
        'watch', 'story', 'magic', 'music', 'color', 'paint', 'draw', 'paper', 'class', 'teach',
        'learn', 'study', 'lunch', 'snack', 'juice', 'plate', 'spoon', 'fork', 'knife', 'clean',
        'dirty', 'small', 'large', 'short', 'long', 'round', 'square', 'sweet', 'sour', 'fresh',
        'earth', 'world', 'space', 'stars', 'moon', 'plant', 'grass', 'flower', 'animal', 'bird',
        'fish', 'horse', 'sheep', 'puppy', 'kitty', 'bunny', 'teddy', 'hello', 'again', 'please',
        'thank', 'sorry', 'maybe', 'always', 'never', 'often', 'where', 'when', 'which', 'while',
        'white', 'brown', 'black', 'yellow', 'orange', 'purple', 'people', 'child', 'woman', 'man'
    ],
    hard: [
        'absence', 'accommodate', 'achieve', 'acquire', 'address', 'advertise', 'advice', // advise is different
        'affect', // effect is different
        'aggression', 'allegiance', 'allot', 'already', 'although', 'analysis', 'ancient',
        'apparent', 'appearance', 'appreciate', 'approach', 'appropriate', 'approximate', 'arctic',
        'argument', 'ascend', 'assistance', 'association', 'athlete', 'attendance', 'audience',
        'authority', 'available', 'awkward', 'balance', 'bargain', 'basically', 'beginning',
        'believe', 'benefit', 'bicycle', 'breathe', // breath is different
        'brilliant', 'budget', 'building',
        'business', 'calendar', 'campaign', 'candidate', 'capacity', 'category', 'cemetery',
        'certain', 'challenge', 'character', 'chief', 'choose', // chose is different
        'colleague', 'column',
        'committee', 'communicate', 'community', 'competition', 'complement', // compliment is different
        'complete',
        'complex', 'concern', 'condemn', 'condition', 'conference', 'confidence', 'congratulate',
        'conscience', 'conscious', 'consequence', 'consider', 'consistent', 'continuous', 'control',
        'convenience', 'correspond', 'criticise', // criticize is alternate
        'curiosity', 'cylinder', 'decision',
        'decrease', 'definite', 'definition', 'delicious', 'dependent', 'describe', 'desperate',
        'determine', 'develop', 'dialogue', 'dictionary', 'disappear', 'discipline', 'disease',
        'dissatisfied', 'distinct', 'disturb', 'division', 'dominant', 'easily', 'ecology',
        'ecstasy', 'efficient', 'eighth', 'either', 'eligible', 'eliminate', 'embarrass',
        'emphasize', 'encourage', 'enormous', 'enough', 'entrance', 'envelope', 'environment', // moved from very hard maybe? still hard
        'equipment', 'especially', 'essential', 'establish', 'eventually', 'exaggerate', 'examine',
        'excellent', 'except', // accept is different
        'exercise', 'exhaust', 'exhilarate', 'existence', 'expense',
        'experience', 'experiment', 'explanation', 'extreme', 'familiar', 'fascinate', 'favorite',
        'february', 'finally', 'financial', 'foreign', 'formerly', 'fortunately', 'forward', // not foreword
        'frequent', 'fulfill', 'fundamental', 'further', 'future', 'generally', 'generous',
        'genius', 'genuine', 'government', 'grammar', 'grateful', 'guarantee', 'guidance',
        'harass', 'height', 'heir', 'holiday', 'honest', 'however', 'humorous', 'hygiene',
        'ignorance', 'illegible', 'illuminate', 'immediately', 'immense', 'important', 'incidentally',
        'incredible', 'independent', 'indicate', 'individual', 'influence', 'initial', 'innocent',
        'intelligence', 'interest', 'interfere', 'interrupt', 'introduce', 'irrelevant', 'irresistible',
        'island', 'its', // it's is different
        'jealous', 'jewelry', // jewellery is alternate
        'journey', 'judgment', // judgement is alternate
        'kernel', // colonel is different
        'kindergarten', 'knowledge', // moved from very hard? borderline
        'laboratory', 'language', 'laughter', 'league',
        'leisure', 'length', 'liable', 'liaison', 'license', // licence is alternate noun
        'lightning', // not lightening
        'likely', 'literally', 'literature', 'livelihood', 'loneliness', 'loose', // lose is different
        'luxury', 'machine', 'magazine', 'maintain', 'maintenance', 'manageable', 'manoeuvre', // maneuver is alternate
        'marriage', 'mathematics', 'maximum', 'measure', 'medicine', 'medieval', 'mediocre',
        'millionaire', 'miniature', 'minimum', 'minuscule', 'minute', // time unit
        'miracle', 'mirror',
        'miscellaneous', 'mischievous', 'missile', 'mission', 'mistake', 'moment', 'monitor',
        'mortgage', 'mountain', 'multiple', 'muscle', 'museum', 'mysterious', 'narrative',
        'natural', 'nausea', 'necessary', // moved from very hard? borderline
        'negative', 'negotiate', 'neighbor', // neighbour is alternate
        'neither', 'nervous', 'neutral', 'niece', 'noticeable', 'nuclear', 'nuisance',
        'numerous', 'occasion', 'occur', 'occurrence', 'official', 'omit', 'operate',
        'opinion', 'opportunity', // moved from very hard? borderline
        'opposite', 'ordinary', 'origin', 'parallel', // moved from very hard? borderline
        'particular', 'pastime', 'patience', 'peculiar', 'perceive', 'perform', 'permanent',
        'permission', 'personnel', // personal is different
        'persuade', 'physical', 'physician', 'piece', // peace is different
        'pleasant', 'pneumonia', 'poison', 'policy', 'political', 'possess', 'possession',
        'possible', 'potential', 'practical', 'practice', // practise is alternate verb
        'precede', // proceed is different
        'precise', 'prefer', 'preference', 'prejudice', 'preparation', 'presence', // presents is different
        'pressure', 'previous', 'primitive', 'principal', // principle is different
        'priority', 'privilege',
        'probably', 'procedure', 'process', 'produce', 'profession', 'professor', 'program', // programme is alternate
        'pronounce', 'pronunciation', 'proof', 'property', 'propose', 'psychology', 'publicly',
        'purpose', 'pursue', 'quality', 'quantity', 'queue', 'quiet', // quite is different
        'realize', // realise is alternate
        'really', 'reason', 'receipt', 'receive', 'recognize', // recognise is alternate
        'recommend', 'reduce',
        'reference', 'referring', 'regular', 'rehearse', 'reign', // rain, rein are different
        'relevant', 'relieve',
        'religious', 'remember', 'repetition', 'representative', 'require', 'research', 'resistance',
        'resource', 'respect', 'response', 'responsibility', 'restaurant', 'rhythm', // moved from very hard? borderline
        'ridiculous',
        'sacrifice', 'safety', 'salary', 'satellite', 'satisfy', 'sauce', // source is different
        'schedule',
        'science', 'scissors', 'season', 'secretary', 'seize', 'separate', 'sergeant', 'several',
        'shoulder', 'signature', 'significant', 'similar', 'sincerely', 'soldier', 'solemn',
        'sophisticated', 'source', 'souvenir', 'special', 'specific', 'speech', 'sponsor',
        'stationary', // stationery is different
        'statistics', 'statue', 'stomach', 'straight', // strait is different
        'strength', 'stretch', 'structure', 'stubborn', 'subtle', 'succeed', 'success',
        'sufficient', 'suggest', 'summary', 'superintendent', 'supersede', 'suppose', 'surprise',
        'surround', 'suspicious', 'symbol', 'sympathy', 'system', 'technical', 'technique',
        'technology', 'temperature', 'temporary', 'tendency', 'tension', 'terrible', 'their', // there, they're are different
        'theory', 'therefore', 'thorough', 'though', // thought, thru, through are different
        'thousand', 'threaten',
        'throughout', 'tomorrow', 'tongue', 'tragedy', 'transfer', 'transmit', 'transparent',
        'travel', 'tremendous', 'triangle', 'truly', 'twelfth', 'typical', 'unanimous',
        'undoubtedly', 'unfortunate', 'unique', 'unnecessary', 'until', 'useful', 'usual',
        'vacuum', 'valuable', 'variety', 'vegetable', 'vehicle', 'version', 'victim',
        'village', 'villain', 'visible', 'visitor', 'volume', 'voluntary', 'vulnerable',
        'wander', // wonder is different
        'weather', // whether is different
        'wednesday', 'weird', 'welcome', 'whereas',
        'whichever', 'whole', // hole is different
        'whose', // who's is different
        'width', 'worst', // worth is different
        'writing', 'yacht', 'yield'
    ],
    veryHard: [
        // Expanded list of 100 challenging words
        'aberration', 'abnegation', 'acquiesce', 'alacrity', 'ambiguous',
        'anachronistic', 'antediluvian', 'antithesis', 'apocryphal', 'approbation',
        'archipelago', 'assiduous', 'auspicious', 'bourgeois', 'bureaucracy',
        'cacophony', 'capitulate', 'capricious', 'catharsis', 'caustic',
        'chicanery', 'circumlocution', 'clairvoyant', 'cognizant', 'commensurate',
        'complaisant', 'concomitant', 'conflagration', 'conscientious', 'conundrum',
        'corpulent', 'corroborate', 'credulous', 'cryptic', 'ubiquitous',
        'curmudgeon', 'deleterious', 'demagogue', 'denigrate', 'derogatory',
        'desiccated', 'diaphanous', 'dichotomy', 'didactic', 'diffident',
        'dilatory', 'discombobulate', 'disparate', 'dissemble', 'ebullient',
        'effervescent', 'egregious', 'embezzlement', 'emollient', 'enervate',
        'ephemeral', 'epiphany', 'equivocate', 'erudite', 'esoteric',
        'euphemism', 'exacerbate', 'exculpate', 'execrable', 'exorbitant',
        'expedient', 'fastidious', 'fatuous', 'garrulous', 'gregarious',
        'hegemony', 'hierarchy', 'idiosyncratic', 'ignominious', 'impecunious',
        'impetuous', 'impugn', 'incandescent', 'inchoate', 'incontrovertible',
        'indefatigable', 'ineffable', 'inexorable', 'inimical', 'innocuous',
        'insidious', 'intransigent', 'inundate', 'irascible', 'juxtaposition',
        'laconic', 'laudable', 'legerdemain', 'licentious', 'limpid',
        'magnanimous', 'malapropism', 'maudlin', 'mellifluous', 'mendacious'
    ]
};

let currentWord = '';
let currentDifficulty = 'medium'; // Default difficulty
let synth = window.speechSynthesis; // Text-to-speech API
let voices = []; // To store available voices

function populateVoiceList() {
  voices = synth.getVoices();
  // console.log("Available voices:", voices); // Optional: Log voices for debugging
}

// Fetch voices when they are loaded
populateVoiceList();
if (synth.onvoiceschanged !== undefined) {
  synth.onvoiceschanged = populateVoiceList;
}

function speak(text) {
    if (synth.speaking) {
        // Optional: Stop current speech before starting new one
        // synth.cancel();
        // console.log('Speech cancelled to speak new word.');
        // Use return for now to prevent overlap issues
        return;
    }
    if (text !== '') {
        const utterThis = new SpeechSynthesisUtterance(text);

        utterThis.onerror = function (event) {
            console.error('SpeechSynthesisUtterance.onerror', event);
            feedback.textContent = 'An error occurred during speech.'; // Inform user
        }

        // Attempt to select a preferred voice
        let selectedVoice = null;
        // Prioritize English voices (US then GB)
        selectedVoice = voices.find(voice => voice.lang === 'en-US');
        if (!selectedVoice) {
            selectedVoice = voices.find(voice => voice.lang === 'en-GB');
        }
        // Fallback to any English voice or default
        if (!selectedVoice) {
            selectedVoice = voices.find(voice => voice.lang.startsWith('en'));
        }

        if (selectedVoice) {
            utterThis.voice = selectedVoice;
            // console.log("Using voice:", selectedVoice.name); // Optional: Log chosen voice
        }

        utterThis.pitch = 1;
        utterThis.rate = 0.9;
        synth.speak(utterThis);
    }
}

function nextWord() {
    // Get the currently selected difficulty level
    const selectedDifficulty = document.querySelector('input[name="difficulty"]:checked')?.value || currentDifficulty;
    currentDifficulty = selectedDifficulty; // Update stored difficulty

    // Select the word list for the current difficulty
    const currentWordList = wordLists[currentDifficulty];

    // Pick a random word from the selected list
    const randomIndex = Math.floor(Math.random() * currentWordList.length);
    currentWord = currentWordList[randomIndex];

    // Clear input and feedback
    spellingInput.value = '';
    feedback.textContent = '';
    feedback.className = ''; // Clear styling
    spellingInput.focus(); // Put cursor in the input field

    // Speak the new word
    speak(currentWord);
}

function checkSpelling() {
    const userAnswer = spellingInput.value.trim().toLowerCase();

    if (userAnswer === currentWord) {
        feedback.textContent = 'Correct!';
        feedback.className = 'correct';
        // Automatically go to the next word after a short delay
        setTimeout(nextWord, 1500); // Wait 1.5 seconds
    } else {
        feedback.textContent = `Not quite! It's spelled: ${currentWord}`; // Show correct spelling
        feedback.className = 'incorrect';
        // Optional: Speak the word again for reinforcement
        // speak(currentWord);
    }
}

// Event Listeners
hearWordButton.addEventListener('click', () => {
    if (currentWord) {
        speak(currentWord);
    }
});

checkButton.addEventListener('click', checkSpelling);

// Allow pressing Enter in the input field to check spelling
spellingInput.addEventListener('keypress', (event) => {
    if (event.key === 'Enter') {
        checkSpelling();
    }
});

// --- Initial Load ---

document.addEventListener('DOMContentLoaded', () => {
    // Set up difficulty change listener
    const difficultyRadios = document.querySelectorAll('input[name="difficulty"]');
    difficultyRadios.forEach(radio => {
        radio.addEventListener('change', () => {
            // Update currentDifficulty based on selection
            currentDifficulty = radio.value;
            // Load a new word immediately from the new difficulty level
            nextWord();
        });
    });

    // A small delay might be needed for speech synthesis to be ready
    setTimeout(() => {
        nextWord(); // Load initial word based on default checked radio
        spellingInput.focus();
    }, 500);

    // Check for speech synthesis support
    if (!('speechSynthesis' in window)) {
        feedback.textContent = 'Sorry, your browser does not support text-to-speech!';
        hearWordButton.disabled = true;
        checkButton.disabled = true;
        // Disable difficulty selection too if speech doesn't work
        difficultyRadios.forEach(radio => radio.disabled = true);
    }
}); 