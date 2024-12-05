const rulesFile = Bun.file("./rules.txt");
const rulesText = await rulesFile.text();
const rules: Rule[] = [];

interface Rule {
  first: string;
  later: string;
}

for (const line of rulesText.split("\n")) {
  const [p1, p2] = line.split("|");
  rules.push({ first: p1, later: p2 });
}

//console.log(rules);

const updatesFile = Bun.file("./updates.txt");
const updatesText = await updatesFile.text();
const lines = updatesText.split("\n");

const invalidUpdates: Array<Array<string>> = [];

let sum = 0;
for (const line of lines) {
  //const line = lines[1];
  const pages = line.split(",");
  if (pages.length < 2) continue;

  let updateValid = true;
  for (let i = 0; i < pages.length - 1; i++) {
    const p = pages[i];
    const n = pages[i + 1];
    if (!rules.find((r: Rule) => r.first == p && r.later == n)) {
      updateValid = false;
    }
  }

  if (!updateValid) {
    invalidUpdates.push(pages);
  } else {
    const centerIndex = Math.floor(pages.length / 2);
    sum += parseInt(pages[centerIndex]);
  }
}

console.log(invalidUpdates.length, lines.length, sum);

const fixInvalids = (inv: number[]) => {
  let atLeastOneError = false;
  for (let i = 0; i < inv.length - 1; i++) {
    const p = inv[i];
    const n = inv[i + 1];
    const foundRule = rules.find((r: Rule) => r.first == n && r.later == p);
    if (foundRule) {
      inv[i] = n;
      inv[i + 1] = p;

      atLeastOneError = true;
    }
  }
  if (atLeastOneError) {
    fixInvalids(inv);
  } else {
    return;
  }
};

let repSum = 0;
for (const inv of invalidUpdates) {
  //const inv = invalidUpdates[0];
  const centerIndex = Math.floor(inv.length / 2);

  fixInvalids(inv);

  console.log("patched invalid", inv);
  console.log(inv[centerIndex]);
  repSum += parseInt(inv[centerIndex]);
}

console.log("repsum", repSum);
