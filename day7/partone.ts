import { perm } from "./permute";

const inputFile = Bun.file("./input.txt");
const inputText = await inputFile.text();

interface Op {
  name: string;
  doIt: (v1: number, v2: number) => number;
}

const Plus: Op = {
  name: "+",
  doIt: (v1: number, v2: number): number => {
    return v1 + v2;
  },
};

const Mult: Op = {
  name: "*",
  doIt: (v1: number, v2: number): number => {
    return v1 * v2;
  },
};

const Conc: Op = {
  name: "||",
  doIt: (v1: number, v2: number): number => {
    return parseInt(`${v1}${v2}`);
  },
};

const foundLines: string[] = [];

class Equation {
  line: string;
  result: number;
  operands: number[];
  ops: Op[] = [Plus, Mult, Conc];
  permOps: Op[][];

  constructor(line: string) {
    this.line = line;
    const [res, rest] = line.split(":");
    this.result = parseInt(res);

    this.operands = [];
    const operands = rest.split(/\s/);
    for (const operand of operands) {
      const trimmed = operand.trim();
      if (trimmed.length > 0) {
        this.operands.push(parseInt(trimmed));
      }
    }
    this.permOps = perm(this.operands.length - 1, this.ops);
  }

  calc = (): number => {
    console.log("---\nSolving", this.line);
    for (const ops of this.permOps) {
      let result = this.operands[0];

      //console.log("trying ops variant:", ops.map((o) => o.name).join("|"));
      for (let i = 0; i < this.operands.length - 1; i++) {
        const value = this.operands[i + 1];
        const op = ops[i];
        result = op.doIt(result, value);
      }

      if (result == this.result) {
        console.log(
          "Found solver",
          ops.map((o) => o.name).join("|"),
          "for:",
          this.line,
          "with result",
          result,
        );
        foundLines.push(this.line);
        return result;
      }
    }
    return 0;
  };
}

const equations: Equation[] = [];
const lines = inputText.split("\n");
for (const line of lines) {
  if (line.trim().length > 0) {
    equations.push(new Equation(line));
  }
}

var total = 0;
for (const eq of equations) {
  //.slice(2, 5)) {
  const calculated = eq.calc();
  console.log("calculated", calculated, "prev total", total);
  total += calculated;
}

console.log(total);

console.log(foundLines.sort().join("\n"));
console.log(
  foundLines
    .map((fl) => parseInt(fl.split(":")[0]))
    .reduce((n, s) => {
      s += n;
      return s;
    }, 0),
);
