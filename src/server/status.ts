
export enum EStatus {
    Out = 'Out',
    Here = 'Here',
    Meeting = 'Meeting'
}

export type Status = EStatus | string;

export class User {
    public name: string = '';
    public status: Status = EStatus.Out;
}

export class Dept {
    public name: string = '';
    public users: User[] = [];
    public children: Dept[] = [];
}