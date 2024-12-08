export const perm = <T>(length: number, values: T[]): T[][] => {
  const result: T[][] = [];

  //zero value;
  if (values.length == 0) return result;

  //one value
  const p = Array<T>(length).map(() => values[0]);
  result.push(p);
  if (values.length == 1) return result;

  const permutations = doPerm([], length, values, result);
  return permutations.filter((arr) => arr.some((v) => !!v));
};

//var breakCounter = 0;
const doPerm = <T>(
  currentArray: T[],
  length: number,
  values: T[],
  collector: T[][],
): T[][] => {
  //breakCounter++;
  if (currentArray.length == length) {
    collector.push(currentArray);
    return collector;
  }

  for (let j = 0; j < values.length; j++) {
    //console.log("adding value", values[j]);
    const nextArray = [...currentArray];
    nextArray.push(values[j]);
    doPerm(nextArray, length, values, collector);
  }

  return collector;
};

const values = ["A", "B"];
const permutations = perm(2, values);
console.log(permutations);
