const rulesFile = Bun.file("./rules.txt");
const rulesText = await rulesFile.text();
const rules: Record<string, string[]> = {};

for (const line of rulesText.split("\n")) {
  const [p1, p2] = line.split("|");

  const existingRule = rules[p1];
  if (existingRule) {
    existingRule.push(p2);
  } else {
    rules[p1] = [p2];
  }
}

//console.log(rules);

const updatesFile = Bun.file("./updates.txt");
const updatesText = await updatesFile.text();
const lines = updatesText.split("\n");

let sum = 0;
for (const line of lines) {
  //const line = lines[1];
  const pages = line.split(",");
  if (pages.length < 2) continue;

  let updateValid = true;
  for (let i = 0; i < pages.length - 1; i++) {
    const p = pages[i];
    if (!rules[p].includes(pages[i + 1])) {
      updateValid = false;
    }
  }

  if (updateValid) {
    const centerIndex = Math.floor(pages.length / 2);
    sum += parseInt(pages[centerIndex]);
  }
}

console.log("Sum: ", sum);
