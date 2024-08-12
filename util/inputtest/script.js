let names, readings;

async function loadData() {
//    const namesResponse = await fetch('names.json');
//    names = await namesResponse.json();

    const namesResponse = await fetch('names.txt');
    const namesText = await namesResponse.text();
    names = parseNames(namesText);
    
    const readingsResponse = await fetch('dictionary.txt');
    const readingsText = await readingsResponse.text();
    readings = parseReadings(readingsText);
//    console.log(readings["bg"]);
}

function parseReadings(text) {
    const readingsObject = [];
    const lines = text.split('\n');
    for (const line of lines) {
        const [key, value] = line.trim().split('=');
        if (key && value) {
            readingsObject[key] = value;
        }
    }
    return readingsObject;
}

function parseNames(text) {
    const namesObject = [];
    const lines = text.split('\n');
    for (const line of lines) {
    	if(line){
	        namesObject.push(line.trim());
	    }
    }
    return namesObject;
}

function getReading(name) {
    let result = [];
    let remainingName = name;

    while (remainingName.length > 0) {
        let bestMatch = '';
        let bestMatchLength = 0;
        for (const [key, value] of Object.entries(readings)) {
            if (remainingName.startsWith(value) && value.length > bestMatchLength) {
                bestMatch = key;
                bestMatchLength = value.length;
            }
        }
        if (bestMatch) {
            result.push(bestMatch);
            remainingName = remainingName.slice(bestMatchLength);
        } else {
            remainingName = remainingName.slice(1);
        }
    }
    return result.join(' ');
}

function generateNameSets(count) {
    const container = document.getElementById('nameContainer');
    container.innerHTML = '';

    for (let i = 0; i < count; i++) {
        const name = names[Math.floor(Math.random() * names.length)];
        const reading = getReading(name);

        const nameSet = document.createElement('div');
        nameSet.className = 'name-set';
        nameSet.innerHTML = `
            <div class="s1"><label>姓名：</label>${name}</div>
            <div class="s2"><label>読み：</label>${reading}</div>
            <div class="s3"><label>入力：</label><input type="text" placeholder=""></div>
        `;
        container.appendChild(nameSet);
    }
}

document.addEventListener('DOMContentLoaded', async () => {
    await loadData();
    
    const setCountSelect = document.getElementById('setCount');
    setCountSelect.addEventListener('change', () => {
        generateNameSets(parseInt(setCountSelect.value));
    });

    generateNameSets(5); // 初期表示
});