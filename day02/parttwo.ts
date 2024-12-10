const file = Bun.file("./input.txt");
const text = await file.text();
const lines = text.split("\n");

const checkReport = (report: number[]): boolean => {
  let prevValue: number | null = null;
  let globalInc: boolean | null = null;

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
      return false;
    }

    const diff = Math.abs(currentValue - prevValue);
    if (diff < 1 || diff > 3) {
      return false;
    }

    prevValue = currentValue;
  }

  return true;
};

let count = 0;
for (const line of lines) {
  const report = line.split(/\s/).map((s: string) => parseInt(s));
  if (report.length < 2) continue;

  let good = checkReport(report);
  if (!good) {
    for (let index = 0; index < report.length; index++) {
      const modifiedReport = [...report];
      modifiedReport.splice(index, 1);

      const modifiedGood = checkReport(modifiedReport);
      if (modifiedGood) {
        good = modifiedGood;
        break;
      }
    }
  }

  if (good) {
    console.log("Good report", report);
    count++;
  }
}

console.log("Count", count);
