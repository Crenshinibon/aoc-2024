const xor = (v1: number, v2: number): number => v1 ^ v2;
const or = (v1: number, v2: number): number => v1 | v2;
const and = (v1: number, v2: number): number => v1 & v2;

interface Node {
  id: string;
}

interface Transition {
  from_1: Node;
  from_2: Node;
  op: (v1: number, v2: number) => number;
  to: Node;
}

const rFile = Bun.readTextFile("./small_r.txt");
for (const l of rFile.split("\n")) {
  const parts = l.split("\s");

  const in1 = parts[0];
  const opString = parts[1];
  const in2 = parts[2];
  const out = parts[4];

  let nodes: Record<string, Node> = {};
  let transitions: Transition[] = [];

  if (opString == "XOR") {
  } else if (opString == "OR") {
  } else if (opString == "AND") {
  }
}
