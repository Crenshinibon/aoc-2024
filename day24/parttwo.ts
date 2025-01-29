const xor = (v1: number, v2: number): number => v1 ^ v2;
const or = (v1: number, v2: number): number => v1 | v2;
const and = (v1: number, v2: number): number => v1 & v2;

interface NNode {
  id: string;
  value?: number;
  incoming?: Transition;
  inputsFor: (value: number) => NNode;
}

interface Transition {
  from_1: NNode;
  from_2: NNode;
  op: (v1: number, v2: number) => number;
  to: NNode;
}

const nodes: Record<string, NNode> = {};
const transitions: Transition[] = [];

const file = Bun.file("./input_r.txt");
const text = await file.text();

for (const l of text.split("\n")) {
  if (l.length == 0) continue;

  const parts = l.split(/\s/);
  const in1 = parts[0];
  const opString = parts[1];
  const in2 = parts[2];
  const out = parts[4];

  let op: null | ((v1: number, v2: number) => number);
  if (opString == "XOR") {
    op = xor;
  } else if (opString == "OR") {
    op = or;
  } else if (opString == "AND") {
    op = and;
  } else {
    console.log(opString);
    throw Error(opString);
  }

  let in1Node: NNode = nodes[in1];
  if (!in1Node) {
    in1Node = {
      id: in1,
    };
    nodes[in1] = in1Node;
  }

  let in2Node: NNode = nodes[in2];
  if (!in2Node) {
    in2Node = {
      id: in2,
    };
    nodes[in2] = in2Node;
  }

  let outNode: NNode = nodes[out];
  if (!outNode) {
    outNode = {
      id: out,
    };
  }

  const t: Transition = {
    from_1: in1Node,
    from_2: in2Node,
    op: op,
    to: outNode,
  };

  outNode.incoming = t;
  nodes[out] = outNode;

  transitions.push(t);
}

const targetNodes = Object.values(nodes).filter((n) => n.id[0] == "z");

const traverse = (tNode: NNode, collector: Record<string, NNode>) => {
  collector[tNode.id] = tNode;
  if (tNode.incoming) {
    //console.log("Following:", tNode.incoming.from_1.id);
    traverse(tNode.incoming.from_1, collector);
    //console.log("Following:", tNode.incoming.from_2.id);
    traverse(tNode.incoming.from_2, collector);
  } else {
    //console.log("DONE");
  }
};

const dependingNodes: Record<string, NNode> = {};
traverse(targetNodes[0], dependingNodes);

targetNodes[0].inputsFor(1);

console.log(
  Object.values(dependingNodes)
    .filter((d) => d.id[0] == "x" || d.id[0] == "y")
    .sort((d1, d2) => {
      return parseInt(d1.id.substring(1)) - parseInt(d2.id.substring(1));
    })
    .map((d) => d.id),
);
