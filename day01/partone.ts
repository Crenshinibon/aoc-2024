const file = Bun.file("./input.txt");
const text = await file.text();

const firstList: number[] = [];
const secondList: number[] = [];

let sum = 0;
for (const line of text.split("\n")) {
  const [first, second] = line.split(/\s+/);

  if (!first || !second) continue;

  firstList.push(parseInt(first));
  secondList.push(parseInt(second));

  firstList.sort((a: number, b: number) => a - b);
  secondList.sort((a: number, b: number) => a - b);
}

for (let i = 0; i < firstList.length; i++) {
  sum = sum + Math.abs(firstList[i] - secondList[i]);
}

console.log(sum);
