const file = Bun.file("./input.txt");
const text = await file.text();
const lines = text.split("\n");

let count = 0;

for (const line of lines) {
  console.log(line);
  const report = line.split(/\s/).map((s: string) => parseInt(s));
  if (report.length < 2) continue;

  let prevValue: number | null = null;
  let globalInc: boolean | null = null;

  let good = true;

  for (let index = 1; index < report.length; index++) {
    if (!prevValue) {
      prevValue = report[0] as number;
    }
    const currentValue = report[index];
    const inc = prevValue < currentValue;
    if (globalInc == null) {
      globalInc = inc;
    }

    // check rules
    if (inc !== globalInc) {
      good = false;
      break;
    }

    const diff = Math.abs(currentValue - prevValue);
    if (diff < 1 || diff > 3) {
      good = false;
      break;
    }

    prevValue = currentValue;
  }

  if (good) {
    //console.log("Good report", report);
    count++;
  }
}

console.log("Count", count);
