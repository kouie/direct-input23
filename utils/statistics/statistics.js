let allEntries = [];

async function loadData() {
    const response = await fetch('dictionary.txt');
    const text = await response.text();
    return text.split('\n').filter(line => line.trim() !== '').map(line => {
        const [reading, kanji] = line.split('=');
        return { reading: reading.trim(), kanji: kanji ? kanji.trim() : '' };
    });
}

function countChars(entries, getChar) {
    return entries.reduce((acc, entry) => {
        const char = getChar(entry);
        if (char) {
            acc[char] = (acc[char] || 0) + 1;
        }
        return acc;
    }, {});
}

function sortObject(obj) {
    return Object.entries(obj)
        .sort(([,a],[,b]) => b-a)
        .reduce((r, [k, v]) => ({ ...r, [k]: v }), {});
}

function createTable(data, limit) {
    const table = document.createElement('table');
    const thead = table.createTHead();
    const tbody = table.createTBody();

    const headerRow = thead.insertRow();
    headerRow.insertCell().textContent = '文字';
    headerRow.insertCell().textContent = '出現回数';

    Object.entries(data).slice(0, limit).forEach(([char, count]) => {
        const row = tbody.insertRow();
        row.insertCell().textContent = char;
        row.insertCell().textContent = count;
    });

    return table;
}

function create2DTable(data) {
    const table = document.createElement('table');
    const thead = table.createTHead();
    const tbody = table.createTBody();

    const headerRow = thead.insertRow();
    headerRow.insertCell();
    for (const char of Object.keys(data)) {
        headerRow.insertCell().textContent = char;
    }

    for (const [firstChar, secondChars] of Object.entries(data)) {
        const row = tbody.insertRow();
        row.insertCell().textContent = firstChar;
        for (const char of Object.keys(data)) {
            row.insertCell().textContent = secondChars[char] || '';
        }
    }

    return table;
}

function updateTable(tableId) {
    const count = document.getElementById(`${tableId}Count`).value;
    const container = document.getElementById(tableId);
    container.innerHTML = '';

    let data;
    switch (tableId) {
        case 'readingFirstChar':
            data = countChars(allEntries, entry => entry.reading[0]);
            break;
        case 'readingLastChar':
            data = countChars(allEntries, entry => entry.reading[entry.reading.length - 1]);
            break;
        case 'kanjiFirstChar':
            data = countChars(allEntries, entry => entry.kanji && entry.kanji[0]);
            break;
        case 'kanjiLastChar':
            data = countChars(allEntries, entry => entry.kanji && entry.kanji[entry.kanji.length - 1]);
            break;
    }

    container.appendChild(createTable(sortObject(data), parseInt(count)));
}

function extractEntries() {
    const type = document.getElementById('extractType').value;
    const position = parseInt(document.getElementById('extractPosition').value) - 1;
    const char = document.getElementById('extractChar').value;

    if (!char) {
        alert('文字を入力してください。');
        return;
    }

    const result = allEntries.filter(entry => {
        const target = type === 'reading' ? entry.reading : entry.kanji;
        return target[position] === char;
    });

    const container = document.getElementById('extractResult');
    container.innerHTML = '';

    const table = document.createElement('table');
    const thead = table.createTHead();
    const tbody = table.createTBody();

    const headerRow = thead.insertRow();
    headerRow.insertCell().textContent = '読み';
    headerRow.insertCell().textContent = '登録漢字';

    result.forEach(entry => {
        const row = tbody.insertRow();
        row.insertCell().textContent = entry.reading;
        row.insertCell().textContent = entry.kanji;
    });

    container.appendChild(table);
}

async function displayStatistics() {
    allEntries = await loadData();

    document.getElementById('totalEntries').textContent = `エントリの総数: ${allEntries.length}`;

    // 読みの1文字目で集計
    const readingFirstChar = countChars(allEntries, entry => entry.reading[0]);
    document.getElementById('readingFirstChar').appendChild(createTable(sortObject(readingFirstChar)));

    // 読みの末尾の文字で集計
    const readingLastChar = countChars(allEntries, entry => entry.reading[entry.reading.length - 1]);
    document.getElementById('readingLastChar').appendChild(createTable(sortObject(readingLastChar)));
    
    
    updateTable('kanjiFirstChar');
    updateTable('kanjiLastChar');

    const twoCharReadings = allEntries.filter(entry => entry.reading.length === 2 && entry.kanji);
    const twoCharTable = twoCharReadings.reduce((acc, entry) => {
        const [first, second] = entry.reading.split('');
        if (!acc[first]) acc[first] = {};
        acc[first][second] = entry.kanji;
        return acc;
    }, {});
    document.getElementById('twoCharReadings').appendChild(create2DTable(twoCharTable));

    const maxLength = Math.max(...allEntries.map(entry => Math.max(entry.reading.length, entry.kanji.length)));
    const positionSelect = document.getElementById('extractPosition');
    for (let i = 1; i <= maxLength; i++) {
        const option = document.createElement('option');
        option.value = i;
        option.textContent = i;
        positionSelect.appendChild(option);
    }
}

document.addEventListener('DOMContentLoaded', displayStatistics);