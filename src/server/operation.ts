import { Dept, User } from "./status";


type Nothing<T> = {
  readonly isNothing: boolean;
  readonly isJust: boolean;
  with(cbj: (arg: T) => void, cbn: () => void): void;
}
const Nothing = {
  isNothing: true,
  isJust: false,
  with(cbj: (arg: any) => void, cbn: () => void): void {
    return cbn();
  }
}

class Just<T> {
  public readonly isNothing = false;
  public readonly isJust = true;
  private value: T;
  public constructor(val: T) {
    this.value = val;
  }
  public with(cbj: (arg: T) => void, cbn: () => void): void {
    return cbj(this.value);
  }
}

type Maybe<T> = Just<T> | Nothing<T>;



export interface DatAddDept {
  parents: string[];
  name: string;
}
export function addDept(dept: Dept, addInfo: DatAddDept): Maybe<Dept>{
  const searchResult = searchDept(dept, addInfo.parents);
  let ret: Maybe<Dept> = Nothing;
  searchResult.with(x => {
    const newDept = new Dept();
    newDept.name = addInfo.name;
    x.children.push(newDept);
    ret = new Just(newDept);
  }, () => {});

  return ret;
}

function searchDept(dept: Dept, depts: string[]): Maybe<Dept> {
  let same = dept.name === depts[0];
  if (same === false) {
    return Nothing;
  }

  if (depts.length == 1) {
    return new Just(dept);
  }

  const lst = dept.children.map(d => {
    return searchDept(d, depts.slice(1));
  });
  const ret = lst.filter(x => x.isJust);

  return ret.length == 0 ? Nothing : ret[0];
}

/**
 * modifyUserStatus
 * @param dept department
 * @param user user
 */
export function modifyUserStatus(dept: Dept, user: User): boolean {
  for(const u of dept.users) {
    if (u.name === user.name) {
      u.status = user.status;
      return true;
    }
  }

  for(const d of dept.children) {
    const ret = modifyUserStatus(d, user);
    if (ret) {
      return true;
    }
  }

  return false;
}