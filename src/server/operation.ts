import { Dept, User } from "./status";


// ****************************************************************************
// Maybe
// ****************************************************************************
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

function mmap<T1, T2>(arg: Maybe<T1>, f: (x: T1) => T2): Maybe<T2> {
  let newVal: Maybe<T2> = Nothing;
  arg.with((x: T1) => {
    newVal = new Just(f(x));
  }, () => {});
  return newVal;
}


//****************************************************************************
// Result
//****************************************************************************
enum EResult {
  Ok = 'Ok',
  Err = 'Err'
}
class Ok<T> {
  public kind = EResult.Ok;
  private value: T;
  constructor(x: T) {
    this.value = x;
  }

  public with(ok: (x: T) => void, err: (x: any) => void) {
    return ok(this.value);
  }
}
class Err<T> {
  public kind = EResult.Err;
  private value: T;
  constructor(x: T) {
    this.value = x;
  }
  public with(ok: (x: any) => void, err: (x: T) => void) {
    return err(this.value);
  }
}
type Result<T, S> = Ok<T> | Err<S>


function rmap<T1, T2, T3>(arg: Result<T1, T2>, f: (x: T1) => T3): Result<T3, T2> {
  let newVal: Result<T3, T2> = arg as Err<T2>;
  arg.with((x: T1) => {
    newVal = new Ok(f(x));
  }, (x: T2) => {
    newVal = arg as Err<T2>;
  });

  return newVal;
}


// ****************************************************************************
// MaddDept
// ****************************************************************************
export interface DatAddDept {
  parents: string[];
  name: string;
}
/**
 * Adds dept
 * @param dept 
 * @param addInfo 
 * @returns dept 
 */
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

// ****************************************************************************
// modifyUserStatus
// ****************************************************************************
/**
 * modifyUserStatus
 * @param dept department
 * @param user user
 */
export function modifyUserStatus(dept: Dept, user: User): Maybe<[Dept, User]>{
  const searchResult = searchUser(dept, user.name);
  searchResult.with(x => {
    x[1].status= user.status;
  }, () => {});

  return searchResult;
}

function searchUser(dept: Dept, name: string): Maybe<[Dept, User]> {
  for(const u of dept.users) {
    if (u.name === name) {
      return new Just([dept, u]);
    }
  }
  const lst = dept.children.map(d => {
    return searchUser(d, name);
  });
  const ret = lst.filter(x => x.isJust);

  return ret.length == 0 ? Nothing : ret[0];
}

// ****************************************************************************
// addUser
// ****************************************************************************
export interface DatAddUser {
  dept: string[];
  name: string;
}
export function addUser(dept: Dept, user: DatAddUser): Maybe<User> {
  const searchResult = searchDept(dept, user.dept);
  let ret: Maybe<User> = Nothing;
  searchResult.with(x => {
    const newUser = new User();
    newUser.name = user.name;
    x.users.push(newUser);
    ret = new Just(newUser);
  }, () => {});

  return ret;
}

// ****************************************************************************
// moveUser
// ****************************************************************************
export interface DatMoveUser {
  name: string;
  newDept: string[];
}
export function moveUser(dept: Dept, user: DatMoveUser): Maybe<[Dept, User]> {
  const searchResultUser = searchUser(dept, user.name);
  const searchResultDept = searchDept(dept, user.newDept);
  let ret: Maybe<[Dept, User]> = Nothing;
  searchResultUser.with(u => {
    searchResultDept.with(d => {
      const org = u[0].users;
      u[0].users = org.filter(x => x.name !== user.name);
      d.users.push(u[1]);
      ret = new Just(u);
    }, () => {})
  }, () => {});

  return ret;
}
