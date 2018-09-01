var https = require('follow-redirects').https;
var url = "https://champion.gg";
var champions = [
	"Aatrox",
	"Ahri",
	"Akali",
	"Alistar",
	"Amumu",
	"Anivia",
	"Annie",
	"Ashe",
	"AurelionSol",
	"Azir",
	"Bard",
	"Blitzcrank",
	"Brand",
	"Braum",
	"Caitlyn",
	"Camille",
	"Cassiopeia",
	"ChoGath",
	"Corki",
	"Darius",
	"Diana",
	"DrMundo",
	"Draven",
	"Ekko",
	"Elise",
	"Evelynn",
	"Ezreal",
	"Fiddlesticks",
	"Fiora",
	"Fizz",
	"Galio",
	"Gangplank",
	"Garen",
	"Gnar",
	"Gragas",
	"Graves",
	"Hecarim",
	"Heimerdinger",
	"Illaoi",
	"Irelia",
	"Ivern",
	"Janna",
	"JarvanIV",
	"Jax",
	"Jayce",
	"Jhin",
	"Jinx",
	"KaiSa",
	"Kalista",
	"Karma",
	"Karthus",
	"Kassadin",
	"Katarina",
	"Kayle",
	"Kayn",
	"Kennen",
	"KhaZix",
	"Kindred",
	"Kled",
	"KogMaw",
	"LeBlanc",
	"LeeSin",
	"Leona",
	"Lissandra",
	"Lucian",
	"Lulu",
	"Lux",
	"Malphite",
	"Malzahar",
	"Maokai",
	"MasterYi",
	"MissFortune",
	"Mordekaiser",
	"Morgana",
	"Nami",
	"Nasus",
	"Nautilus",
	"Nidalee",
	"Nocturne",
	"Nunu",
	"Olaf",
	"Orianna",
	"Ornn",
	"Pantheon",
	"Poppy",
	"Pyke",
	"Quinn",
	"Rakan",
	"Rammus",
	"RekSai",
	"Renekton",
	"Rengar",
	"Riven",
	"Rumble",
	"Ryze",
	"Sejuani",
	"Shaco",
	"Shen",
	"Shyvana",
	"Singed",
	"Sion",
	"Sivir",
	"Skarner",
	"Sona",
	"Soraka",
	"Swain",
	"Syndra",
	"TahmKench",
	"Taliyah",
	"Talon",
	"Taric",
	"Teemo",
	"Thresh",
	"Tristana",
	"Trundle",
	"Tryndamere",
	"TwistedFate",
	"Twitch",
	"Udyr",
	"Urgot",
	"Varus",
	"Vayne",
	"Veigar",
	"VelKoz",
	"Vi",
	"Viktor",
	"Vladimir",
	"Volibear",
	"Warwick",
	"Wukong",
	"Xayah",
	"Xerath",
	"XinZhao",
	"Yasuo",
	"Yorick",
	"Zac",
	"Zed",
	"Ziggs",
	"Zilean",
	"Zoe",
	"Zyra"
];
var c = 0

var finalList = "local levelPresets = {";

function parseData(str, skill, arr) {
	var realStart = str.indexOf('<div class="skill-selections">');
	str = str.substring(realStart + 30);
	var xyz = str.split('<div class="');
	

	for (var i = 0; i < xyz.length; i++) {
		var l = xyz[i];

		if (l.indexOf('selected') != -1) {
			arr[i - 1] = "'"+skill+"'";
		}
	}
}

function reqChamp(champ, num) {
	https.get(url + "/" + champ, (resp) => {
	let data = '';

	// A chunk of data has been recieved.
	resp.on('data', (chunk) => {
		data += chunk;
	});

	// The whole response has been received. Print out the result.
	resp.on('end', () => {
		// Parse the Data
		var start = data.indexOf('Most Frequent Skill Order');
		var ende = data.indexOf('Highest Win % Runes');
		var subs = data.substring(start, ende);

		var skillOrder = subs.indexOf('class="skill"');
		var Q = subs.indexOf('class="skill"', skillOrder + 12);
		var W = subs.indexOf('class="skill"', Q + 12);
		var E = subs.indexOf('class="skill"', W + 12);
		var R = subs.indexOf('class="skill"', E + 12);
		var skillOrder2 = subs.indexOf('class="skill"', R + 12);
		var skillsMostUsed = [];

		parseData(subs.substring(Q, W), "Q", skillsMostUsed);
		parseData(subs.substring(W, E), "W", skillsMostUsed);
		parseData(subs.substring(E, R), "E", skillsMostUsed);
		parseData(subs.substring(R, skillOrder2), "R", skillsMostUsed);

		var Q2 = subs.indexOf('class="skill"', skillOrder2 + 12);
		var W2 = subs.indexOf('class="skill"', Q2 + 12);
		var E2 = subs.indexOf('class="skill"', W2 + 12);
		var R2 = subs.indexOf('class="skill"', E2 + 12);
		var stop = subs.indexOf('class="build-text"', R2 + 12);
		var skillsHighest = [];

		parseData(subs.substring(Q2, W2), "Q", skillsHighest);
		parseData(subs.substring(W2, E2), "W", skillsHighest);
		parseData(subs.substring(E2, R2), "E", skillsHighest);
		parseData(subs.substring(R2, stop), "R", skillsHighest);
		console.log(num, champ)
		finalList += "\n['"+champ+"']={";
		finalList += "\n  ['mostUsed']={" + skillsMostUsed.toString();
		finalList += "},\n  ['highestRate']={" + skillsHighest.toString();
		finalList += "}\n},";

		c += 1;

		if (c == champions.length) {
			finalList += "\n}\n\nreturn levelPresets"

			var fs = require('fs');
			fs.writeFile("levelPresests.lua", finalList, function(err) {
			    if(err) {
			        return console.log(err);
			    }

			    console.log("The file was saved!");
			}); 
		} else {
			reqChamp(champions[num], num + 1)
		}
	});

	}).on("error", (err) => {
		console.log("Error: " + err.message);
	});
}

reqChamp(champions[0], 1);
