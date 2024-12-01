const file = Bun.file("./input.txt");
const text = await file.text();

const firstList: number[] = [];
const secondList: number[] = [];

let sum = 0;
for (let line of text.split("\n")) {
  const [first, second] = line.split(/\s+/);

  if (!first || !second) continue;

  firstList.push(parseInt(first));
  secondList.push(parseInt(second));

  firstList.sort((a: number, b: number) => a - b);
  secondList.sort((a: number, b: number) => a - b);
}

for (const one of firstList) {
  const found = secondList.filter((two) => two == one);
  sum = sum + one * found.length;
}

console.log(sum);
